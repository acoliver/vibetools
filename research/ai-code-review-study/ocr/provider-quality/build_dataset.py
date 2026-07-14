#!/usr/bin/env python3
"""Build the provider-quality datasets from retained, redacted OCR outputs."""

from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

OUT = Path(__file__).resolve().parent

RUNS = [
    {
        "run_id": "QZC",
        "timestamp_local": "2026-07-13T22:14:42-0300",
        "repository": "vybestack/llxprt-code",
        "provider": "Z.ai",
        "model": "GLM-5.2",
        "source": Path("$TMPDIR/ocr_zai_glm.log"),
        "format": "json",
        "head_or_range": "b8ee089626e88952161a17191e213e33048d5e5c",
        "stage": "temporary updated merge for OCR review",
        "matched_pair_id": "M001",
        "attribution_evidence": "operator-named zai_glm artifact; same-head Z.ai endpoint companion 10m earlier; retained Z.ai GLM-5.2 config",
        "attribution_confidence": "high",
        "concurrency_evidence": "not recorded",
        "diff_size_evidence": "90 reviewed files; changed-line count not retained",
    },
    {
        "run_id": "QSC",
        "timestamp_local": "2026-07-13T22:24:37-0300",
        "repository": "vybestack/llxprt-code",
        "provider": "StepFun",
        "model": "Step-3.7-Flash",
        "source": Path("$TMPDIR/ocr_final.log"),
        "format": "json",
        "head_or_range": "b8ee089626e88952161a17191e213e33048d5e5c",
        "stage": "same temporary updated merge for OCR review",
        "matched_pair_id": "M001",
        "attribution_evidence": "16 warning records name api.stepfun.ai; retained StepFun config names step-3.7-flash",
        "attribution_confidence": "high",
        "concurrency_evidence": "warnings report current=16 provider limit=15",
        "diff_size_evidence": "90 reviewed files; changed-line count not retained",
    },
    {
        "run_id": "QZJ",
        "timestamp_local": "2026-07-10T20:49:44-0300",
        "repository": "vybestack/llxprt-jefe",
        "provider": "Z.ai",
        "model": "GLM-5.2",
        "source": Path("$TMPDIR/ocr_issue184_review.log"),
        "format": "plain",
        "head_or_range": "issue184 worktree; exact HEAD/range not retained",
        "stage": "issue review",
        "matched_pair_id": "",
        "attribution_evidence": "run falls inside retained Z.ai GLM-5.2 configuration interval",
        "attribution_confidence": "medium",
        "concurrency_evidence": "not recorded",
        "diff_size_evidence": "48 reviewed files; changed-line count not retained",
    },
    {
        "run_id": "QZL",
        "timestamp_local": "2026-07-12T00:08:23-0300",
        "repository": "vybestack/llxprt-luther",
        "provider": "Z.ai",
        "model": "GLM-5.2",
        "source": Path("$TMPDIR/ocr_issue131.log"),
        "format": "plain",
        "head_or_range": "issue131 worktree; exact HEAD/range not retained",
        "stage": "issue review",
        "matched_pair_id": "",
        "attribution_evidence": "run falls inside retained Z.ai GLM-5.2 configuration interval",
        "attribution_confidence": "medium",
        "concurrency_evidence": "not recorded",
        "diff_size_evidence": "10 reviewed files; changed-line count not retained",
    },
    {
        "run_id": "QSJ",
        "timestamp_local": "2026-07-14T05:09:24-0300",
        "repository": "vybestack/llxprt-jefe",
        "provider": "StepFun",
        "model": "Step-3.7-Flash",
        "source": Path("$TMPDIR/ocr_review_294_stepfun.log"),
        "format": "plain",
        "head_or_range": "issue294 worktree; exact HEAD/range not retained",
        "stage": "post-remediation provider rerun",
        "matched_pair_id": "",
        "attribution_evidence": "operator-named stepfun artifact inside retained StepFun Step-3.7-Flash config interval",
        "attribution_confidence": "high",
        "concurrency_evidence": "not recorded",
        "diff_size_evidence": "52 reviewed files; changed-line count not retained",
    },
    {
        "run_id": "QSL",
        "timestamp_local": "2026-07-14T05:06:54-0300",
        "repository": "vybestack/llxprt-luther",
        "provider": "StepFun",
        "model": "Step-3.7-Flash",
        "source": Path("$TMPDIR/ocr_issue135_stepfun.log"),
        "format": "json",
        "head_or_range": "HEAD in luther worktree; immutable SHA not retained",
        "stage": "later issue135 remediation-stage review",
        "matched_pair_id": "",
        "attribution_evidence": "operator-named stepfun artifact and exact retained session inside StepFun Step-3.7-Flash config interval",
        "attribution_confidence": "high",
        "concurrency_evidence": "not recorded",
        "diff_size_evidence": "18 reviewed files; changed-line count not retained",
    },
]

# Independent adjudication of every finding in exact matched pair M001.
# V=valid, P=partially valid/overstated, I=invalid or unsupported.
ADJUDICATION = {
    "QZC": ["V","V","V","P","V","V","V","V","V","I","P","V","P","P","I","V","V","P","P","V","V","P","V","I","P","I","V","V","P","V","V","P","V","V","P","V","P","P","P","P","P","V","V","P","V","V","V","P","P","P","V","P","P","V","V","V","V","V","V","V","V"],
    "QSC": ["P","V","I","V","V","P","V","V","V","V","I","P","P","P","P","V","V","I","V","P","V","V","V","P","V","V","P","V","P","V","I"],
}
assert len(ADJUDICATION["QZC"]) == 61
assert len(ADJUDICATION["QSC"]) == 31

DUPLICATE_GROUPS = {
    "QZC": {
        "importActual-hook": [1, 3, 21, 23, 30, 42, 46, 55],
        "createApp-return": [24, 28],
        "descriptor-double-read": [25, 29],
        "shutdown-exit-code": [31, 33],
    },
    "QSC": {"proxy-end-close": [8, 9, 10]},
}

OVERLAP = {
    "a2a-reporter-flags": {"QZC": [5], "QSC": [1]},
    "endpoint-as-never": {"QZC": [16], "QSC": [4]},
    "endpoint-reconstruct-mock": {"QZC": [17], "QSC": [5]},
    "proxy-end-close": {"QZC": [27], "QSC": [8, 9, 10]},
    "lsp-vitest-dependency": {"QZC": [39], "QSC": [14]},
    "real-10ms-timer": {"QZC": [45], "QSC": [17]},
    "env-restore-error": {"QZC": [47], "QSC": [19]},
    "env-shared-map": {"QZC": [48], "QSC": [20]},
    "importActual-hook": {"QZC": [1, 3, 21, 23, 30, 42, 46, 55], "QSC": [28]},
    "stub-restore-snapshot": {"QZC": [61], "QSC": [30]},
}

# Context was attached to the wrong file/path in the emitted finding.
STALE_CONTEXT = {
    "QZC": {1, 2, 3, 21, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 38, 42, 46},
    "QSC": set(),
}

# Exact claim/code changes visible in the subsequent commit explicitly titled
# "fix(test): address Bun migration review findings". Because both reviews ran
# before that commit, this is action evidence, not provider-specific causation.
ACTIONED = {
    "QZC": {1, 3, 12, 14, 15, 16, 17, 18, 21, 23, 24, 28, 30, 34, 39, 40, 42, 46, 54, 56, 57, 59, 61},
    "QSC": {4, 5, 6, 7, 14, 25, 26, 27, 28, 30},
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_json_log(path: Path) -> tuple[dict, list[dict]]:
    text = path.read_text(errors="replace")
    decoder = json.JSONDecoder()
    for match in re.finditer(r"\{", text):
        try:
            value, _ = decoder.raw_decode(text[match.start() :])
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict) and "status" in value and "summary" in value:
            return value, value.get("comments", [])
    raise ValueError(f"No OCR JSON object in {path}")


def parse_plain_log(path: Path) -> tuple[dict, list[dict]]:
    text = path.read_text(errors="replace")
    text = re.sub(r"\[[0-9;]*m", "", text)
    summary_match = re.search(
        r"\[ocr\] Summary: (\d+) file\(s\) reviewed, (\d+) comment\(s\), "
        r"~(\d+) token\(s\) used \(input: ~(\d+), output: ~(\d+)\), "
        r"cache\(read: ~(\d+), write: ~(\d+)\), ([^\n]+) elapsed",
        text,
    )
    if not summary_match:
        raise ValueError(f"No OCR summary in {path}")
    files, comments, total, inp, out, cache_read, cache_write, elapsed = summary_match.groups()
    pattern = re.compile(
        r"^─── (.*?):(\d+)-(\d+) ───\n"
        r"\[([^·\]]+) · ([^\]]+)\] (.*?)"
        r"(?=\n\n\n─── |\Z)",
        re.MULTILINE | re.DOTALL,
    )
    findings = []
    for match in pattern.finditer(text):
        file, start, end, category, severity, block = match.groups()
        prose = re.split(r"\n\n(?=[ +\-])", block.strip(), maxsplit=1)[0]
        findings.append(
            {
                "path": file,
                "start_line": int(start),
                "end_line": int(end),
                "category": category.strip(),
                "severity": severity.strip(),
                "content": prose.strip(),
                "suggestion_code": "" if prose == block.strip() else "present-in-plain-output",
                "existing_code": "present-in-plain-output" if prose != block.strip() else "",
            }
        )
    if len(findings) != int(comments):
        raise ValueError(f"Parsed {len(findings)} of {comments} comments in {path}")
    data = {
        "status": "success",
        "summary": {
            "files_reviewed": int(files),
            "comments": int(comments),
            "total_tokens": int(total),
            "input_tokens": int(inp),
            "output_tokens": int(out),
            "cache_read_tokens": int(cache_read),
            "cache_write_tokens": int(cache_write),
            "elapsed": elapsed,
        },
        "warnings": [],
        "session_id": "not-retained-in-plain-output",
    }
    return data, findings


def duplicate_metadata(run_id: str, sequence: int) -> tuple[str, str]:
    for group, members in DUPLICATE_GROUPS.get(run_id, {}).items():
        if sequence in members:
            return group, "no" if sequence == members[0] else "yes"
    return "", "no"


def overlap_group(run_id: str, sequence: int) -> str:
    for group, members_by_run in OVERLAP.items():
        if sequence in members_by_run.get(run_id, []):
            return group
    return ""


def usefulness(adjudication: str, severity: str, duplicate: str) -> str:
    if not adjudication:
        return "not_adjudicated"
    if adjudication == "invalid" or duplicate == "yes":
        return "low"
    if adjudication == "partial":
        return "medium" if severity in {"critical", "high"} else "low"
    if severity in {"critical", "high"}:
        return "high"
    if severity == "medium":
        return "medium"
    return "low"


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


run_rows: list[dict] = []
finding_rows: list[dict] = []
parsed_by_run: dict[str, tuple[dict, list[dict]]] = {}

for run in RUNS:
    parser = parse_json_log if run["format"] == "json" else parse_plain_log
    data, findings = parser(run["source"])
    parsed_by_run[run["run_id"]] = (data, findings)
    summary = data["summary"]
    warning_count = len(data.get("warnings", []))
    run_rows.append(
        {
            "run_id": run["run_id"],
            "timestamp_local": run["timestamp_local"],
            "repository": run["repository"],
            "provider": run["provider"],
            "model": run["model"],
            "provider_endpoint_class": "Z.ai API" if run["provider"] == "Z.ai" else "StepFun API",
            "provider_attribution": run["attribution_evidence"],
            "attribution_confidence": run["attribution_confidence"],
            "head_or_range": run["head_or_range"],
            "remediation_stage": run["stage"],
            "matched_pair_id": run["matched_pair_id"],
            "status": data["status"],
            "files_reviewed": summary["files_reviewed"],
            "findings": len(findings),
            "findings_per_reviewed_file": f"{len(findings) / summary['files_reviewed']:.6f}",
            "distinct_finding_paths": len({f["path"] for f in findings}),
            "finding_words": sum(len(f["content"].split()) for f in findings),
            "mean_words_per_finding": f"{sum(len(f['content'].split()) for f in findings) / len(findings):.6f}",
            "total_tokens": summary.get("total_tokens", ""),
            "output_tokens": summary.get("output_tokens", ""),
            "warning_count": warning_count,
            "concurrency_evidence": run["concurrency_evidence"],
            "diff_size_evidence": run["diff_size_evidence"],
            "session_id": data.get("session_id", ""),
            "source_path": str(run["source"]),
            "source_sha256": sha256(run["source"]),
            "retention_note": "retained temporary artifact; nonrandom survivorship sample",
        }
    )

    for sequence, finding in enumerate(findings, 1):
        code = ADJUDICATION.get(run["run_id"], [])[sequence - 1] if run["run_id"] in ADJUDICATION else ""
        adjudication = {"V": "valid", "P": "partial", "I": "invalid", "": "not_adjudicated"}[code]
        duplicate_group, duplicate = duplicate_metadata(run["run_id"], sequence)
        action = "fixed_after_pair" if sequence in ACTIONED.get(run["run_id"], set()) else (
            "no_direct_fix" if run["matched_pair_id"] else "not_assessed"
        )
        if action == "fixed_after_pair":
            no_action_reason = ""
            action_evidence = "e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf (paired exposure; not provider-specific causation)"
        elif action == "not_assessed":
            no_action_reason = "outside independently adjudicated matched pair"
            action_evidence = ""
        elif duplicate == "yes":
            no_action_reason = "duplicate/rephrased claim"
            action_evidence = ""
        elif adjudication == "invalid":
            no_action_reason = "invalid/unsupported"
            action_evidence = ""
        elif adjudication == "partial":
            no_action_reason = "partial/speculative or remedy not selected"
            action_evidence = ""
        else:
            no_action_reason = "no direct change found in review-remediation commit"
            action_evidence = ""
        content = finding["content"].strip()
        finding_rows.append(
            {
                "finding_id": f"{run['run_id']}-{sequence:03d}",
                "run_id": run["run_id"],
                "matched_pair_id": run["matched_pair_id"],
                "repository": run["repository"],
                "provider": run["provider"],
                "model": run["model"],
                "path": finding["path"],
                "start_line": finding.get("start_line", 0),
                "end_line": finding.get("end_line", 0),
                "category": finding.get("category", ""),
                "severity": finding.get("severity", ""),
                "word_count": len(content.split()),
                "content_sha256": hashlib.sha256(content.encode()).hexdigest(),
                "excerpt": re.sub(r"\s+", " ", content)[:240],
                "has_suggestion": "yes" if finding.get("suggestion_code") else "no",
                "has_existing_code": "yes" if finding.get("existing_code") else "no",
                "duplicate_group": duplicate_group,
                "is_duplicate_or_rephrase": duplicate,
                "semantic_overlap_group": overlap_group(run["run_id"], sequence),
                "adjudication": adjudication,
                "usefulness": usefulness(adjudication, finding.get("severity", ""), duplicate),
                "context_status": "stale_or_misattributed" if sequence in STALE_CONTEXT.get(run["run_id"], set()) else (
                    "grounded" if run["matched_pair_id"] else "not_assessed"
                ),
                "action_status": action,
                "no_action_reason": no_action_reason,
                "action_evidence": action_evidence,
                "source_path": str(run["source"]),
                "source_sha256": sha256(run["source"]),
            }
        )

write_csv(
    OUT / "provider-runs.csv",
    run_rows,
    list(run_rows[0]),
)
write_csv(
    OUT / "provider-findings.csv",
    finding_rows,
    list(finding_rows[0]),
)

matched_rows = [
    {
        "pair_id": "M001",
        "repository": "vybestack/llxprt-code",
        "head_or_range": "b8ee089626e88952161a17191e213e33048d5e5c",
        "zai_run_id": "QZC",
        "stepfun_run_id": "QSC",
        "same_head": "yes",
        "same_reviewed_file_denominator": "yes (90/90)",
        "elapsed_between_starts": "9m55s",
        "zai_findings": 61,
        "stepfun_findings": 31,
        "zai_unique_claims": 51,
        "stepfun_unique_claims": 29,
        "overlapping_semantic_claims": 10,
        "claim_union": 70,
        "jaccard_overlap": "0.142857",
        "zai_claims_overlapped": "0.196078",
        "stepfun_claims_overlapped": "0.344828",
        "zai_status": "success",
        "stepfun_status": "completed_with_errors",
        "zai_subtask_warnings": 0,
        "stepfun_subtask_warnings": 16,
        "input_equivalence": "same commit and 90-file denominator; exact selected-file manifest absent",
        "major_confounder": "StepFun lost 16 subtasks to provider-reported concurrency; Z.ai emitted file-read errors despite success status",
        "action_evidence": "e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf changed reviewed areas after both runs",
        "causal_limit": "paired exposure means fixes cannot be credited to one provider when claims overlap",
    }
]
write_csv(OUT / "matched-reruns.csv", matched_rows, list(matched_rows[0]))


def summary_row(scope: str, provider: str, selected: list[dict]) -> dict:
    runs = [r for r in run_rows if r["run_id"] in {x["run_id"] for x in selected}]
    findings = [f for f in finding_rows if f["run_id"] in {x["run_id"] for x in selected}]
    files = sum(int(r["files_reviewed"]) for r in runs)
    n = len(findings)
    unique = n - sum(f["is_duplicate_or_rephrase"] == "yes" for f in findings)
    adjudicated = [f for f in findings if f["adjudication"] != "not_adjudicated"]
    count = lambda field, value: sum(f[field] == value for f in findings)
    acount = lambda field, value: sum(f[field] == value for f in adjudicated)
    row = {
        "scope": scope,
        "provider": provider,
        "model": selected[0]["model"],
        "repositories": ";".join(sorted({x["repository"] for x in selected})),
        "runs": len(runs),
        "reviewed_files": files,
        "findings": n,
        "findings_per_reviewed_file": f"{n / files:.6f}",
        "unique_claims": unique,
        "unique_claims_per_reviewed_file": f"{unique / files:.6f}",
        "mean_words_per_finding": f"{sum(int(f['word_count']) for f in findings) / n:.6f}",
        "critical": count("severity", "critical"),
        "high": count("severity", "high"),
        "medium": count("severity", "medium"),
        "low": count("severity", "low"),
        "bug_or_correctness_or_reliability": sum(f["category"] in {"bug", "correctness", "reliability"} for f in findings),
        "maintainability": count("category", "maintainability"),
        "test": count("category", "test"),
        "duplicate_or_rephrase": count("is_duplicate_or_rephrase", "yes"),
        "duplicate_rate": f"{count('is_duplicate_or_rephrase', 'yes') / n:.6f}",
        "adjudicated_n": len(adjudicated),
        "valid": acount("adjudication", "valid"),
        "partial": acount("adjudication", "partial"),
        "invalid": acount("adjudication", "invalid"),
        "valid_rate": f"{acount('adjudication', 'valid') / len(adjudicated):.6f}" if adjudicated else "",
        "valid_or_partial_rate": f"{(acount('adjudication', 'valid') + acount('adjudication', 'partial')) / len(adjudicated):.6f}" if adjudicated else "",
        "usefulness_high": acount("usefulness", "high"),
        "usefulness_medium": acount("usefulness", "medium"),
        "usefulness_low": acount("usefulness", "low"),
        "stale_or_misattributed": acount("context_status", "stale_or_misattributed"),
        "stale_context_rate": f"{acount('context_status', 'stale_or_misattributed') / len(adjudicated):.6f}" if adjudicated else "",
        "fixed_after_pair": acount("action_status", "fixed_after_pair"),
        "finding_level_action_rate": f"{acount('action_status', 'fixed_after_pair') / len(adjudicated):.6f}" if adjudicated else "",
        "unique_claim_action_rate": (
            f"{len({(f['duplicate_group'] or f['finding_id']) for f in findings if f['action_status'] == 'fixed_after_pair'}) / unique:.6f}"
            if scope == "matched M001" else ""
        ),
        "line_located": sum(int(f["start_line"]) > 0 for f in findings),
        "has_suggestion": count("has_suggestion", "yes"),
        "note": "manual duplicate/adjudication/action/context metrics only for M001" if scope == "matched M001" else "unmatched stratified descriptive sample; duplicate/adjudication/action/context not assessed outside M001",
    }
    if scope != "matched M001":
        for field in (
            "unique_claims", "unique_claims_per_reviewed_file",
            "duplicate_or_rephrase", "duplicate_rate", "adjudicated_n",
            "valid", "partial", "invalid", "valid_rate",
            "valid_or_partial_rate", "usefulness_high",
            "usefulness_medium", "usefulness_low",
            "stale_or_misattributed", "stale_context_rate",
            "fixed_after_pair", "finding_level_action_rate",
            "unique_claim_action_rate",
        ):
            row[field] = ""
    return row

matched_z = [r for r in RUNS if r["run_id"] == "QZC"]
matched_s = [r for r in RUNS if r["run_id"] == "QSC"]
strat_z = [r for r in RUNS if r["provider"] == "Z.ai"]
strat_s = [r for r in RUNS if r["provider"] == "StepFun"]
quality_rows = [
    summary_row("matched M001", "Z.ai", matched_z),
    summary_row("matched M001", "StepFun", matched_s),
    summary_row("stratified retained sample", "Z.ai", strat_z),
    summary_row("stratified retained sample", "StepFun", strat_s),
]
write_csv(OUT / "quality-summary.csv", quality_rows, list(quality_rows[0]))

# A deliberately simple chart; only the exact matched 90-file denominator is shown.
svg = """<svg xmlns="http://www.w3.org/2000/svg" width="760" height="360" viewBox="0 0 760 360" role="img" aria-labelledby="title desc">
<title id="title">Matched OCR finding volume per 90 reviewed files</title>
<desc id="desc">Z.ai GLM-5.2 emitted 61 findings and 51 deduplicated claims. StepFun Step-3.7-Flash emitted 31 findings and 29 deduplicated claims. The StepFun run had 16 failed subtasks.</desc>
<rect width="760" height="360" fill="#fafafa"/>
<text x="50" y="38" font-family="system-ui,sans-serif" font-size="20" fill="#1f2937">Matched run M001 — same commit, 90 reviewed files</text>
<text x="50" y="62" font-family="system-ui,sans-serif" font-size="13" fill="#4b5563">Counts are descriptive; StepFun had 16 failed subtasks.</text>
<line x1="190" y1="300" x2="710" y2="300" stroke="#9ca3af"/>
<text x="45" y="135" font-family="system-ui,sans-serif" font-size="14" fill="#1f2937">Z.ai GLM-5.2</text>
<text x="45" y="235" font-family="system-ui,sans-serif" font-size="14" fill="#1f2937">StepFun 3.7 Flash</text>
<rect x="190" y="100" width="488" height="30" fill="#4678a8"/>
<rect x="190" y="135" width="408" height="22" fill="#9ab8d3"/>
<rect x="190" y="200" width="248" height="30" fill="#b36b3f"/>
<rect x="190" y="235" width="232" height="22" fill="#d7aa8d"/>
<text x="686" y="121" font-family="system-ui,sans-serif" font-size="14" fill="#1f2937">61 findings</text>
<text x="606" y="152" font-family="system-ui,sans-serif" font-size="14" fill="#1f2937">51 unique</text>
<text x="446" y="221" font-family="system-ui,sans-serif" font-size="14" fill="#1f2937">31 findings</text>
<text x="430" y="252" font-family="system-ui,sans-serif" font-size="14" fill="#1f2937">29 unique</text>
<text x="190" y="325" font-family="system-ui,sans-serif" font-size="12" fill="#4b5563">0</text>
<text x="670" y="325" font-family="system-ui,sans-serif" font-size="12" fill="#4b5563">60 findings</text>
</svg>
"""
(OUT / "matched-finding-volume.svg").write_text(svg)

print(f"wrote {len(run_rows)} runs and {len(finding_rows)} findings")
for row in quality_rows:
    print(row)
