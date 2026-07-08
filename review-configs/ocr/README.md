# Open Code Review (OCR) Configuration Templates

Portable templates for [OpenCodeReview](https://www.npmjs.com/package/@alibaba-group/open-code-review)
(ocr), the AI-powered code review CLI. These templates let any project drop in
a production-quality automated review setup in minutes.

## What's included

| File | What it is |
| --- | --- |
| `rule.json` | Global review rubric: senior-engineer priority order (correctness → contract → edge cases → type safety → security → maintainability), lint/complexity guardrail enforcement (flags suppression directives, severity downgrades, threshold increases across ESLint, clippy, ruff), and multi-language test-include patterns. |
| `includes/rust.json` | Rust-specific test-include/exclude patterns for `rule.json`. |
| `includes/typescript.json` | TypeScript-specific test-include/exclude patterns for `rule.json`. |
| `includes/python.json` | Python-specific test-include/exclude patterns for `rule.json`. |
| `ocr-review.yml` | Language-configurable GitHub Actions CI workflow. Fork-safe (`pull_request_target`), posts findings as a sticky PR comment. Triggers on PR open/sync/reopen and `/ocr` comment. **244 lines** — radically simplified from the 1297-line source. |
| `review-prompt.md` | Rigorous multi-phase plan-review prompt (12 review dimensions, BLOCKER/MAJOR/MINOR/PEDANTIC severity, PASS/FAIL verdict with evidence). De-repo-ified from jefe. |
| `open-code-review.toml` | Agent command definition: background-launch pattern, polling workflow, scope-preview-first methodology, finding classification rubric. De-repo-ified from llxprt-code. |

## Quick start

### 1. Set up the global rule

```sh
mkdir -p ~/.opencodereview
cp review-configs/ocr/rule.json ~/.opencodereview/rule.json
```

For a language-specific include set (if you don't want the multi-language
default), merge the appropriate `includes/<lang>.json` into `rule.json`.

### 2. Configure the LLM provider

```sh
# Example: z.ai Anthropic-compatible endpoint
cat > ~/.opencodereview/config.json <<CONF
{
  "provider": "zai-anthropic",
  "model": "glm-5.2",
  "apiKey": "<your-api-key>"
}
CONF
```

Never commit API keys to a repo. Use environment variables or the system
keyring.

### 3. Add the CI workflow (optional)

```sh
cp review-configs/ocr/ocr-review.yml your-project/.github/workflows/ocr-review.yml
```

Then edit the `LANGUAGE` env var at the top of the workflow to match your
project (`rust`, `typescript`, or `python`).

Set these repo secrets/variables in GitHub:

| Type | Name | Example |
| --- | --- | --- |
| Secret | `OCR_LLM_AUTH_TOKEN` | your-api-key |
| Variable | `OCR_LLM_URL` | `https://api.z.ai/api/anthropic` |
| Variable | `OCR_LLM_MODEL` | `glm-5.2` |
| Variable | `OCR_LLM_USE_ANTHROPIC` (optional) | `true` |

The workflow is observational (non-blocking). Pair it with your lint/test CI
gate as the required check.

### 4. Use the plan-review prompt (optional)

Point an AI agent at `review-prompt.md` alongside your plan documents to get a
rigorous pre-execution review. Fill in the placeholder paths for your project's
standards docs.

## Sources

- **rule.json** — ported and extended from `~/.opencodereview/rule.json`. Added
  Rust (`#[allow(...)]`, clippy thresholds) and Python (`noqa`, ruff thresholds)
  suppression/threshold detection.
- **ocr-review.yml** — radically simplified from `jefe/.github/workflows/ocr-review.yml`
  (1297 → 244 lines). Removed: inline-comment posting with dedup, secret
  redaction of all artifacts, infrastructure-failure auto-issue notification,
  artifact upload, changed-test-file scope verification. Kept: fork-safe
  checkout, language-configurable test includes, sticky summary comment, `/ocr`
  comment trigger. These features can be re-added per-project if needed.
- **review-prompt.md** — ported from `jefe/project-plans/issue20/.review-prompt.md`,
  de-repo-ified (removed jefe/Rust-specific references).
- **open-code-review.toml** — ported from `~/.llxprt/commands/open-code-review.toml`,
  de-repo-ified.
