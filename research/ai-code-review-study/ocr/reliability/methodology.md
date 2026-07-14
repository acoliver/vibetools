# Methodology

## Question and scope

This documentary audit asks how reliably local OpenCodeReview (OCR) produced review output while supporting `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, and `vybestack/llxprt-luther`, and how observed failures relate to provider/account transitions. The retained measurement window is **2026-07-10 through 2026-07-14 local time (-03:00)**; one earlier Ollama configuration snapshot supplies chronology but no canonical run in that period.

## Evidence hierarchy

1. **Direct execution output:** `$TMPDIR/ocr*.log|json` and two nested Jefe `.jefe/ocr_review.log` files.
2. **Session corroboration:** metadata and selected known phrase matches in `~/.opencodereview/sessions`; 3,154 JSONL files totaling 18,323,743,955 bytes, including 1,081 empty files. Full payload replication was avoided because it contains code and unrelated user data.
3. **Configuration chronology:** current and backup `~/.opencodereview/config.json*`; credentials were never copied. File timestamps, provider, endpoint host, protocol, and model were retained.
4. **Existing OCR research:** the parent report's 36 PR and 23 local findings and PR-2462 overlap analysis.
5. **Official vendor pages:** directly fetched Ollama, Z.ai, and StepFun documentation/pricing, captured as short extracts and URLs rather than full pages.
6. **User-supplied account facts:** Ollama top consumer subscription; older top-tier annual Z.ai subscription with higher limits; StepFun Pro previously and StepFun Max now. These facts are explicitly labeled, not independently inferred.

## Run unit and deduplication

A run event is one retained artifact containing direct OCR execution status (`[ocr] Summary`, JSON `status`, or terminal `review failed`). Preview files, PID/exit/status/nohup companions, extracted findings, test logs, CI research snapshots, and comments were excluded. Same-stem `.log`/`.json` companions were folded into one event. Session JSONL was used only as corroboration and never counted as another run. This conservative rule yielded **145 canonical attempts**.

The dataset is **not** a census. Temporary-file retention is opportunistic; successful and failure logs may be overwritten or absent; filenames are operator-selected; session retention is uneven and includes empty files. Metrics therefore describe retained evidence, not the population reliability of OCR.

## Classification

- `success`: terminal summary or JSON success with no explicit subtask errors.
- `partial`: `completed_with_errors` or completed output with one or more `subtask_error` records.
- `failure`: no usable completion, classified by the strongest direct marker.
- Failure taxonomy: partial/subtask, HTTP 429/rate limit, authentication/config, timeout/termination, network/server, malformed/model/tool, missing/lost output, unknown.
- For partial runs, `notes` records the direct causal marker (HTTP 429 or HTTP 529 overload). Thus the mutually exclusive `failure_class` remains `partial/subtask failure`, while causal counts remain available.

Broad words such as “timeout” or “rate limit” in reviewed source code were not treated as operational failure evidence. Only execution-context markers such as `LLM completion error ... 429`, `overloaded_error`, `completed_with_errors`, or terminal `review failed` were used.

## Provider and repository attribution

Explicit provider endpoint/model/path markers override configuration inference. Otherwise provider is inferred within intervals bounded by retained config timestamps in `provider-timeline.csv`. Pre-2026-07-10 18:36 attempts remain `unknown` rather than being assigned to Ollama. Model names come from config snapshots: GLM-5.2 for Ollama/Z.ai and Step-3.7-Flash for StepFun.

Repository/worktree comes from a nearest-in-time session parent (within ten minutes), nested worktree path, or unambiguous source-layout clues. Unknown attribution is retained when evidence is insufficient. All canonical artifacts are local executions; no retained event was labeled as a PR CI execution. A local run may support a PR without being the PR workflow.

## Aggregation and interpretation

`generate-reliability-chart.py` reads only `run-events.csv`, creates period and daily CSVs, and renders dependency-free SVG/PNG charts. Percentages use `n / attempts × 100`, shown to one decimal place. “Usable output” combines success and partial; it is **not** full review coverage.

Observations are direct counts or source statements. Interpretations explain plausible operational implications. Recommendations apply a reliability criterion: preserve coverage, make missing coverage observable, and lower retry/triage burden.
