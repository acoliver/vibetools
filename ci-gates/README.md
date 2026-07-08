# CI Quality Gate Templates

Radically simplified, language-specific GitHub Actions CI workflows. Each
template is a single job with sequential steps: lint → format check →
typecheck → test (with coverage) → build. All include concurrency control
and caching.

## What's here

| Directory | Language | Steps | Lines |
| --- | --- | --- | --- |
| [`typescript/`](typescript/ci.yml) | TypeScript (Node + npm) | ESLint (--max-warnings 0), Prettier check, tsc, Vitest --coverage, build | ~47 |
| [`rust/`](rust/ci.yml) | Rust | cargo fmt --check, clippy -D warnings, build --locked, test --locked | ~46 |
| [`python/`](python/ci.yml) | Python (uv) | ruff check, ruff format --check, mypy --strict, pytest --coverage | ~43 |
| [`bun/`](bun/ci.yml) | Bun | Biome check, tsc --noEmit, bun test --coverage | ~40 |
| [`deno/`](deno/ci.yml) | Deno | deno fmt --check, deno lint, deno check, deno test --coverage | ~43 |

## Quick start

```sh
cp ci-gates/<language>/ci.yml your-project/.github/workflows/ci.yml
```

Then adjust paths (e.g., `src/`, test directories) and version numbers for
your project.

## What every gate has

- **Triggers:** `push: [main]` + `pull_request` (all branches).
- **Concurrency:** Cancel in-progress on PR pushes; never cancel on main so
  trunk CI always completes.
- **Single sequential job:** one job, steps in order, any failure stops the
  pipeline. No matrix fan-out.
- **Caching:** Language-appropriate (npm cache, rust-cache, uv cache, Bun
  cache, Deno cache).
- **Minimal permissions:** `contents: read` only.
- **Zero-tolerance lint:** `--max-warnings 0`, `-D warnings`, `ruff check`.

## What was stripped (vs. source workflows)

The llxprt-code source CI is 544 lines with monorepo workspace fan-out,
sandbox matrix jobs, eval suites, release pipelines, and ratchet pinning.
The jefe source has 8 separate jobs. These templates strip all of that and
keep only the quality gate.

## Relationship to other areas

- **[project-setup/](../project-setup/)** — the lint/complexity configs
  define the rules; the CI gates enforce them. The `init.sh` scripts
  optionally copy the CI gate alongside the lint config.
- **[review-configs/](../review-configs/)** — the OCR review workflow
  (`ocr-review.yml`) is complementary. The CI gate is the blocking check;
  OCR is observational/non-blocking.
- **[planning/templates/](../planning/templates/)** — the planning system
  references quality gates in its verification phases.
