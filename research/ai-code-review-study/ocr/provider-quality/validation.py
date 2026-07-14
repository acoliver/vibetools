#!/usr/bin/env python3
"""Documentary validation for the OCR provider-quality artifacts."""

from __future__ import annotations

import csv
import hashlib
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TARGET = Path(__file__).resolve().parent
REQUIRED = {
    "report.md",
    "provider-runs.csv",
    "provider-findings.csv",
    "matched-reruns.csv",
    "quality-summary.csv",
    "evidence-index.md",
    "methodology.md",
    "source-extracts.md",
    "commands.md",
    "validation.py",
    "build_dataset.py",
    "matched-finding-volume.svg",
    "file-inventory.txt",
}


def fail(message: str) -> None:
    raise AssertionError(message)


def read_csv(name: str) -> list[dict[str, str]]:
    with (TARGET / name).open(newline="") as handle:
        return list(csv.DictReader(handle))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


missing = sorted(name for name in REQUIRED if not (TARGET / name).is_file())
if missing:
    fail(f"missing required artifacts: {missing}")

runs = read_csv("provider-runs.csv")
findings = read_csv("provider-findings.csv")
matched = read_csv("matched-reruns.csv")
summary = read_csv("quality-summary.csv")

if len(runs) != 6:
    fail(f"expected 6 sampled runs, found {len(runs)}")
if len(findings) != 187:
    fail(f"expected 187 finding rows, found {len(findings)}")
if len(matched) != 1 or matched[0]["pair_id"] != "M001":
    fail("expected exactly matched pair M001")
if len(summary) != 4:
    fail(f"expected 4 quality summary rows, found {len(summary)}")

# Provider/model separation and direct source provenance.
allowed = {("Z.ai", "GLM-5.2"), ("StepFun", "Step-3.7-Flash")}
if {(r["provider"], r["model"]) for r in runs} != allowed:
    fail("unexpected provider/model attribution")
if any(r["provider_endpoint_class"].startswith("Ollama") for r in runs):
    fail("no run should be attributed to Ollama")
for run in runs:
    source = Path(run["source_path"])
    if source.is_file() and sha256(source) != run["source_sha256"]:
        fail(f"source hash mismatch: {run['run_id']}")
    if not source.is_file() and not run["source_path"].startswith(("$TMPDIR/", "$HOME/", "$MOUNTED_WORKSPACE/")):
        fail(f"unrecognized redacted source path: {run['source_path']}")

# Every finding points to its run and source hash; IDs are unique.
run_by_id = {r["run_id"]: r for r in runs}
if len(run_by_id) != len(runs):
    fail("duplicate run ID")
if len({f["finding_id"] for f in findings}) != len(findings):
    fail("duplicate finding ID")
for finding in findings:
    run = run_by_id.get(finding["run_id"])
    if run is None:
        fail(f"orphan finding: {finding['finding_id']}")
    if finding["source_path"] != run["source_path"] or finding["source_sha256"] != run["source_sha256"]:
        fail(f"finding provenance mismatch: {finding['finding_id']}")
    if len(finding["content_sha256"]) != 64:
        fail(f"invalid finding hash: {finding['finding_id']}")

# Per-run aggregates.
for run in runs:
    selected = [f for f in findings if f["run_id"] == run["run_id"]]
    if len(selected) != int(run["findings"]):
        fail(f"finding count mismatch: {run['run_id']}")
    if sum(int(f["word_count"]) for f in selected) != int(run["finding_words"]):
        fail(f"word count mismatch: {run['run_id']}")
    expected_density = len(selected) / int(run["files_reviewed"])
    if abs(float(run["findings_per_reviewed_file"]) - expected_density) > 5e-7:
        fail(f"finding density mismatch: {run['run_id']}")

# Exact expected matched metrics.
expected = {
    "Z.ai": {
        "findings": "61", "reviewed_files": "90", "unique_claims": "51",
        "duplicate_or_rephrase": "10", "valid": "35", "partial": "22", "invalid": "4",
        "usefulness_high": "9", "usefulness_medium": "16", "usefulness_low": "36",
        "stale_or_misattributed": "18", "fixed_after_pair": "23",
        "findings_per_reviewed_file": "0.677778", "duplicate_rate": "0.163934",
        "valid_rate": "0.573770", "valid_or_partial_rate": "0.934426",
        "stale_context_rate": "0.295082", "finding_level_action_rate": "0.377049",
        "unique_claim_action_rate": "0.313725", "mean_words_per_finding": "93.508197",
    },
    "StepFun": {
        "findings": "31", "reviewed_files": "90", "unique_claims": "29",
        "duplicate_or_rephrase": "2", "valid": "17", "partial": "10", "invalid": "4",
        "usefulness_high": "5", "usefulness_medium": "12", "usefulness_low": "14",
        "stale_or_misattributed": "0", "fixed_after_pair": "10",
        "findings_per_reviewed_file": "0.344444", "duplicate_rate": "0.064516",
        "valid_rate": "0.548387", "valid_or_partial_rate": "0.870968",
        "stale_context_rate": "0.000000", "finding_level_action_rate": "0.322581",
        "unique_claim_action_rate": "0.344828", "mean_words_per_finding": "76.354839",
    },
}
matched_summary = {r["provider"]: r for r in summary if r["scope"] == "matched M001"}
if set(matched_summary) != set(expected):
    fail("missing matched summary provider")
for provider, fields in expected.items():
    row = matched_summary[provider]
    for field, value in fields.items():
        if row[field] != value:
            fail(f"unexpected {provider} {field}: {row[field]} != {value}")

# Manual adjudication is complete only for pair M001; unmatched manual metrics remain blank.
pair_findings = [f for f in findings if f["matched_pair_id"] == "M001"]
if len(pair_findings) != 92:
    fail("expected 92 matched findings")
if any(f["adjudication"] == "not_adjudicated" for f in pair_findings):
    fail("matched pair has unadjudicated finding")
if any(f["adjudication"] != "not_adjudicated" for f in findings if not f["matched_pair_id"]):
    fail("unmatched finding unexpectedly adjudicated")
for row in summary:
    if row["scope"] != "matched M001":
        for field in ("unique_claims", "duplicate_rate", "valid_rate", "stale_context_rate", "finding_level_action_rate"):
            if row[field]:
                fail(f"unmatched manual metric should be blank: {row['provider']} {field}")

# Overlap identities.
pair = matched[0]
if int(pair["claim_union"]) != int(pair["zai_unique_claims"]) + int(pair["stepfun_unique_claims"]) - int(pair["overlapping_semantic_claims"]):
    fail("claim union identity failed")
if abs(float(pair["jaccard_overlap"]) - 10 / 70) > 5e-7:
    fail("Jaccard mismatch")
overlap_groups = {f["semantic_overlap_group"] for f in pair_findings if f["semantic_overlap_group"]}
if len(overlap_groups) != 10:
    fail(f"expected 10 overlap groups, found {len(overlap_groups)}")

# No-action triage partitions matched findings.
for provider in ("Z.ai", "StepFun"):
    selected = [f for f in pair_findings if f["provider"] == provider]
    if any(f["action_status"] not in {"fixed_after_pair", "no_direct_fix"} for f in selected):
        fail(f"unexpected action status for {provider}")
    if any(not f["no_action_reason"] for f in selected if f["action_status"] == "no_direct_fix"):
        fail(f"missing no-action reason for {provider}")

# Finding hashes cited in source extracts must exist.
all_finding_hashes = {f["content_sha256"] for f in findings}
source_extracts = (TARGET / "source-extracts.md").read_text()
for digest in re.findall(r"finding hash `([0-9a-f]{64})`|SHA `([0-9a-f]{8})…", source_extracts):
    full, prefix = digest
    if full and full not in all_finding_hashes:
        fail(f"unknown cited finding hash: {full}")
    if prefix and not any(value.startswith(prefix) for value in all_finding_hashes):
        fail(f"unknown cited finding hash prefix: {prefix}")

# Relative Markdown links.
for path in TARGET.glob("*.md"):
    text = path.read_text()
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
        if re.match(r"(?:https?://|#|mailto:)", target):
            continue
        clean = target.split("#", 1)[0]
        if clean and not (path.parent / clean).resolve().exists():
            fail(f"broken link in {path.name}: {target}")

# Credential scan: allow redaction words and hashes, reject common live-secret assignments/prefixes.
credential_patterns = [
    re.compile(r"(?i)(?:api[_-]?key|token|secret|password|credential)\s*[\"']?\s*[:=]\s*[\"'][A-Za-z0-9._-]{12,}"),
    re.compile(r"\b(?:sk|ghp|github_pat|xox[baprs])-[-A-Za-z0-9_]{16,}\b"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}"),
]
for path in TARGET.iterdir():
    if not path.is_file() or path.name == "file-inventory.txt":
        continue
    text = path.read_text(errors="ignore")
    for pattern in credential_patterns:
        if pattern.search(text):
            fail(f"possible credential in {path.name}")

# Inventory hashes every final file except itself.
package_root = TARGET.parents[1]
inventory_rows = {}
for line in (TARGET / "file-inventory.txt").read_text().splitlines()[1:]:
    if not line:
        continue
    name, size, digest = line.split("\t")
    inventory_rows[name] = (int(size), digest)
expected_names = sorted(
    path.relative_to(package_root).as_posix()
    for path in TARGET.iterdir()
    if path.is_file() and path.name != "file-inventory.txt"
)
if sorted(inventory_rows) != expected_names:
    fail("inventory file list mismatch")
for name, (size, digest) in inventory_rows.items():
    path = package_root / name
    if path.stat().st_size != size or sha256(path) != digest:
        fail(f"inventory hash mismatch: {name}")

print("PASS: 6 runs; 187 findings; 92 matched findings fully adjudicated")
print("PASS: M001 aggregates, overlap, no-action triage, links, and provenance")
print("PASS: credential scan and public-package inventory")
