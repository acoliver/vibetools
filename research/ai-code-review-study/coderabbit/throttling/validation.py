#!/usr/bin/env python3
import csv
import hashlib
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parent
EXPECTED = {
    "repository-inventory.csv": 3,
    "config-history.csv": 13,
    "pr-activity-by-week.csv": None,
    "chart-timeseries.csv": 28,
    "review-events.csv": 459,
    "rate-limit-events.csv": 256,
    "review-response-updates.csv": 1368,
    "period-summary.csv": 15,
    "policy-timeline.csv": 10,
}
rows = {}
for name, count in EXPECTED.items():
    with (BASE / name).open(newline="") as source:
        records = list(csv.DictReader(source))
        rows[name] = records
    assert records, name
    if count is not None:
        assert len(records) == count, (name, len(records), count)
    assert all(set(record) == set(records[0]) for record in records), name

rates = rows["rate-limit-events.csv"]
assert sum(row["repository"] == "llxprt-code" for row in rates) == 114
assert sum(row["repository"] == "llxprt-jefe" for row in rates) == 89
assert sum(row["repository"] == "llxprt-luther" for row in rates) == 53
assert sum(row["exact_heading"] == "Free tier rate limit reached" for row in rates) == 0
assert len({row["comment_url"] for row in rates}) == 256
assert sum(row["plan_stated"] == "Pro" for row in rates) == 22
assert sum(row["plan_stated"] == "Pro Plus" for row in rates) == 233
last_pro = max(row["created_at"] for row in rates if row["plan_stated"] == "Pro")
first_pro_plus = min(
    row["created_at"] for row in rates if row["plan_stated"] == "Pro Plus"
)
assert last_pro == "2026-06-12T21:07:23Z"
assert first_pro_plus == "2026-06-15T14:07:50Z"

chart = rows["chart-timeseries.csv"]
assert {row["repository"] for row in chart} == {
    "all-llxprt",
    "llxprt-code",
    "llxprt-jefe",
    "llxprt-luther",
}
assert len({row["week_start"] for row in chart}) == 7
for week in {row["week_start"] for row in chart}:
    aggregate = next(
        row for row in chart if row["week_start"] == week and row["repository"] == "all-llxprt"
    )
    projects = [
        row for row in chart if row["week_start"] == week and row["repository"] != "all-llxprt"
    ]
    assert int(aggregate["pr_events"]) == sum(int(row["pr_events"]) for row in projects)
    assert int(aggregate["completed_review_signals"]) == sum(
        int(row["completed_review_signals"]) for row in projects
    )
    assert int(aggregate["blocked_comments"]) == sum(
        int(row["blocked_comments"]) for row in projects
    )
assert (BASE / "activity-over-time.svg").is_file()
assert (BASE / "activity-over-time.png").is_file()
svg = (BASE / "activity-over-time.svg").read_text()
assert "<svg" in svg and "All projects: PR events vs successful reviews vs throttles" in svg

responses = rows["review-response-updates.csv"]
assert sum(row["classification"] == "high_confidence" for row in responses) == 357
assert sum(row["classification"] == "medium_confidence" for row in responses) == 914
assert sum(row["classification"] == "temporal_only" for row in responses) == 97
periods = rows["period-summary.csv"]
assert {(row["period_id"], row["repository"]) for row in periods} == {
    (f"P{index}", repository)
    for index in range(5)
    for repository in ["llxprt-code", "llxprt-jefe", "llxprt-luther"]
}

config = rows["config-history.csv"]
assert sum(row["event_scope"] == "default_branch_workflow" for row in config) == 4
assert sum(row["event_scope"] == "pr_branch_config" for row in config) == 4
assert sum(row["event_scope"] == "default_branch_config" for row in config) == 3
assert sum(row["event_scope"] == "default_branch_nested_config" for row in config) == 1
assert sum(row["event_scope"] == "negative_finding" for row in config) == 1
assert {row["change"] for row in config} <= {"add", "modify", "absent"}
assert not any(row["change"] in {"delete", "rename"} for row in config)
assert all(
    row["pr_state"] == "merged"
    for row in config
    if row["event_scope"] == "pr_branch_config"
)
luther = next(
    row for row in config if row["event_scope"] == "default_branch_nested_config"
)
assert luther["path"] == "workflow/.coderabbit.yaml"
assert luther["commit_sha"] == "259fa5d4919abe33265db93a29f99e18a88088f8"
jefe = next(row for row in config if row["repository"] == "llxprt-jefe")
assert jefe["event_scope"] == "negative_finding" and jefe["change"] == "absent"

# Relative Markdown links.
for markdown in BASE.glob("*.md"):
    text = markdown.read_text()
    for target in re.findall(r"\[[^]]*\]\(([^)]+)\)", text):
        if target.startswith(("http://", "https://", "#", "mailto:")):
            continue
        assert (markdown.parent / target.split("#")[0]).resolve().exists(), (
            markdown,
            target,
        )

# Inventory hashes. The inventory excludes itself and uses package-root paths.
package_root = BASE.parents[1]
inventory = {}
for line in (BASE / "file-inventory.txt").read_text().splitlines()[1:]:
    if not line:
        continue
    relative, size, digest = line.split("	")
    inventory[relative] = (int(size), digest)
for target in sorted(BASE.iterdir()):
    if not target.is_file() or target.name == "file-inventory.txt":
        continue
    relative = target.relative_to(package_root).as_posix()
    actual = (target.stat().st_size, hashlib.sha256(target.read_bytes()).hexdigest())
    assert inventory.get(relative) == actual, target

# Selected comment IDs and the corrected Luther commit/file existence.
for api_path in [
    "repos/vybestack/llxprt-code/issues/comments/4663789403",
    "repos/vybestack/llxprt-jefe/issues/comments/4972172300",
    "repos/vybestack/llxprt-luther/commits/259fa5d4919abe33265db93a29f99e18a88088f8",
    "repos/vybestack/llxprt-luther/contents/workflow/.coderabbit.yaml?ref=main",
]:
    subprocess.run(["gh", "api", api_path, "--silent"], check=True)

print("validation passed:", {name: len(records) for name, records in rows.items()})
