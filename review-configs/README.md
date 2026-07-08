# Review Configuration Templates

Portable templates for automated code review tools. Drop these into any project
to get a production-quality review setup in minutes.

## What's here

| Directory | Tool | What it provides |
| --- | --- | --- |
| [`ocr/`](ocr/) | [OpenCodeReview](https://www.npmjs.com/package/@alibaba-group/open-code-review) | Review rubric (rule.json), language-specific test includes, CI workflow (fork-safe, language-configurable), plan-review prompt, agent command definition. |
| [`coderabbit/`](coderabbit/) | [CodeRabbit](https://coderabbit.ai) | `.coderabbit.yaml` template (assertive profile, lint-guardrail enforcement, tool integration placeholders). |

## Shared philosophy

Both OCR and CodeRabbit templates enforce the same quality bar:

1. **Correctness first** — logic bugs, error handling, async safety, edge cases.
2. **Contract/intent** — code must match its comments, names, and documented
   behavior.
3. **Type safety** — no unnecessary `Any`/`any`; prefer narrowing, `Result`/
   `Option`, discriminated unions.
4. **Security** — injection, unvalidated input, secrets.
5. **Maintainability** — dead code, duplication, non-idiomatic patterns.

### Lint guardrail enforcement

Both templates flag — as High severity — any weakening of static-analysis
guardrails:

- New suppression directives (`eslint-disable`, `ts-ignore`, `#[allow(...)]`,
  `noqa`, `type: ignore`).
- Rule severity downgrades (`error`→`warn`, `error`→`off`, `deny`→`allow`).
- Complexity/size threshold increases (`max-lines`, `cognitive-complexity`,
  `too-many-arguments`, etc.).
- Ignore/exclude blocks that hide source code from linting.

This mirrors the policy enforced by the project-setup templates
(see [`project-setup/`](../project-setup/)) and the planning system
(see [`planning/templates/`](../planning/templates/)).

## Quick start

```sh
# OCR: install the global rule + add the CI workflow
mkdir -p ~/.opencodereview
cp review-configs/ocr/rule.json ~/.opencodereview/rule.json
cp review-configs/ocr/ocr-review.yml your-project/.github/workflows/ocr-review.yml

# CodeRabbit: drop in the config
cp review-configs/coderabbit/.coderabbit.yaml your-project/.coderabbit.yaml
```

See the per-tool READMEs for detailed setup instructions.
