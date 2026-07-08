# CodeRabbit Configuration Template

Portable [CodeRabbit](https://coderabbit.ai) configuration template for any
project. Since neither source repo (llxprt-code, jefe) had an in-repo
`.coderabbit.yaml` (CodeRabbit was configured via the web UI only), this
template was **created from scratch**, deriving its review philosophy from the
shared OCR rubric.

## What's included

| File | What it is |
| --- | --- |
| `.coderabbit.yaml` | CodeRabbit config: language setting, auto-review on PRs from main, assertive profile, custom review instructions mirroring the OCR rubric, tool integration placeholders, path filters. |

## Key design decisions

### Review instructions

The `review_instructions` block mirrors the OCR `rule.json` rubric so both
tools enforce the same quality bar:

1. Correctness (control flow, edge cases, error handling, async safety)
2. Contract mismatch (code vs. comments/names/intent)
3. Type safety (no unnecessary Any, prefer narrowing/Result/Option)
4. Security (injection, unvalidated input, secrets)
5. Maintainability (dead code, duplication, non-idiomatic patterns)

Plus the **lint guardrail policy** — any suppression directive, severity
downgrade, or threshold increase is flagged as High severity. This ensures
CodeRabbit catches the same policy violations that the `check-eslint-guard.js`
script catches in CI.

### Assertive profile

Uses `profile: assertive` (more findings) rather than `chill`. Aligns with the
project philosophy of "strictest possible quality bar." Findings can always be
resolved/dismissed individually; it's harder to find what was never reported.

### Tool integrations (commented out)

Tool blocks (clippy, eslint, biome, ruff, mypy) are commented out by default
because the correct set depends on the project's language. Uncomment the ones
that apply.

## Quick start

```sh
cp review-configs/coderabbit/.coderabbit.yaml your-project/.coderabbit.yaml
```

Then edit:
- `language:` — set to your project's primary language.
- `tools:` — uncomment the linters you use.
- `path_filters:` — uncomment and adjust for your generated/vendored dirs.

CodeRabbit picks up the config automatically on the next PR.

## Relationship to OCR

CodeRabbit and OCR are complementary:
- **CodeRabbit** — runs on every PR automatically via the GitHub App, posts
  inline comments with proposed fixes, tracks walk-through coverage.
- **OCR** — runs on demand (locally or via CI), uses a configurable LLM
  provider, produces structured JSON output for programmatic triage.

Both enforce the same review rubric and lint-guardrail policy.
