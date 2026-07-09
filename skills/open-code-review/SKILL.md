---
name: open-code-review
description: Use this skill when asked to review code changes. Runs OpenCodeReview (ocr) in the background, classifies findings by severity, and applies fixes.
---

# Open Code Review

Review code changes using the `ocr` CLI (Alibaba Open Code Review), then
classify and report the findings. If the user asks to fix, apply validated
fixes for High and Medium findings.

## Prerequisites

### Required tools

- `ocr` (OpenCodeReview CLI) — install: `npm i -g @alibaba-group/open-code-review`
- A configured LLM provider — verify with `ocr llm test`

### Global rule (recommended)

Copy the review rubric and test-include patterns so test files are reviewed
and the senior-engineer rubric is applied automatically:

```sh
mkdir -p ~/.opencodereview
cp review-configs/ocr/rule.json ~/.opencodereview/rule.json
```

Source: `review-configs/ocr/` in this repo. A per-project `.opencodereview/rule.json`
overrides the global one.

## Step 1 — Preview scope (no LLM call, instant)

Always preview which files will be reviewed before running the full review:

```sh
ocr review --preview --from <base> --to <head>
```

Expect test files under "Will review". If a test file shows under
"Excluded ... (default_path)", the global rule is missing — copy it (see
Prerequisites) or pass `--rule <path-to-rule.json>`.

## Step 2 — Run the review in the background

**Never run ocr in the foreground.** Under `--audience agent`, ocr buffers all
output until completion. A foreground run will be killed by the shell's
~2-minute process watchdog, losing all buffered output. A high `timeout` on
the calling tool does NOT save a foreground run.

### 2a. Launch detached with a 20-minute timeout floor

Always pass `--timeout 20` (the default is only 10 minutes). Do NOT reduce it
below 20 unless the user explicitly asks; raise it (e.g., `--timeout 30`) only
for very large reviews.

```sh
nohup ocr review --audience agent --timeout 20 \
  --from <base> --to <head> > /tmp/ocr_review.log 2>&1 &
echo "PID=$!"
```

### 2b. Poll with short tool calls

Repeat until the process is DONE. Output only appears once ocr finishes (it is
buffered):

```sh
sleep 90
ps -p $PID >/dev/null && echo RUNNING || echo DONE
cat /tmp/ocr_review.log
```

Cap total patience at ~25 minutes (the 20-minute `--timeout` floor plus
slack). If a run exceeds ~25 minutes with no output, treat it as hung and
investigate the session logs at `~/.opencodereview/sessions/` (the per-run
`.jsonl` captures all LLM turns and `code_comment` findings even when stdout
was lost).

Use `--format json` when you want structured findings (file, line, severity,
suggestion) to classify programmatically; the default text summary is fine
otherwise.

## Step 3 — Classify and report

Group the review comments by priority:

- **High** — clear bugs, security issues, lint-guardrail violations, or precise,
  fixable suggestions.
- **Medium** — reasonable but context-dependent; maintainability, DRY, missing
  edge-case handling; needs manual work.
- **Low** — likely false positives, nitpicks, style, or comments lacking enough
  context to be actionable; evaluate case by case rather than discarding
  unconditionally.

## Step 4 — Fix (only if the user asked to)

- If the user requested "review and fix": apply High and Medium fixes directly
  when safe; otherwise describe the fix.
- If the user only asked to "review": ask before changing anything.

## Notes

- There is NO config/env key for a default review timeout (`config.json` only
  holds provider/llm/telemetry; env vars are only `OCR_LLM_*`). The 20-minute
  floor is enforced by the `--timeout 20` flag — keep it.
- Test coverage: ocr excludes test files by default. The global
  `~/.opencodereview/rule.json` overrides this with `include` patterns for
  `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, etc., plus a thorough rubric
  (`merge_system_rule: true`). Rule priority: `--rule` >
  `<repo>/.opencodereview/rule.json` > `~/.opencodereview/rule.json` > built-in.
- Full-file review without a diff: `ocr scan --path <dir>` (also honors the
  global rule/include).
- To re-include tests ad-hoc without the global rule, create a rule.json with
  `"include": ["**/*.test.{ts,tsx,js,jsx}", "**/*.spec.{ts,tsx,js,jsx}", "**/__tests__/**"]`
  and pass `--rule <file>`.
