# Python project setup

Canonical Python **lint / type-check / test / coverage** config, distilled from
a production Python codebase and de-repo-ified (project name and paths replaced
with a `YOUR_PACKAGE` placeholder).

## Files

| File | Purpose |
| --- | --- |
| `pyproject.toml` | ruff, mypy (strict), pytest, coverage config. The `[project]` table has placeholders to fill in. |
| `init.sh` | One-command installer — copies/substitutes the config into a target project. |

## Quick start

```sh
# From the root of your Python project (auto-detects package name from dir):
path/to/vibetools/project-setup/python/init.sh .

# Explicit package name:
path/to/vibetools/project-setup/python/init.sh . my_package

# Or via the universal launcher:
path/to/vibetools/project-setup/setup.sh python . my_package
```

Then install dev tools and verify:

```sh
pip install -e '.[dev]'        # or: uv sync --group dev
ruff check .
mypy src tests
pytest --cov
```

## Why these rules

This is a **single-source** setup (one production codebase), so values are kept
as-is — there were no conflicts to resolve.

### Complexity limits

| Tool | Rule | Value |
| --- | --- | --- |
| ruff/mccabe | `max-complexity` | **30** |
| ruff/pylint | `max-args` | **8** |
| ruff/pylint | `max-statements` | **100** |
| ruff/pylint | `max-locals` | **20** |
| ruff/pylint | `max-nested-blocks` | **5** |
| ruff/pylint | `max-bool-expr` | **5** |
| ruff/pylint | `max-returns` | **8** |

### Type checking (mypy)

- `strict = true` — all strict-mode checks on.
- `disallow_any_explicit = true` — no explicit `Any` in signatures.
- `warn_unreachable = true` — flags dead branches.
- **No `# type: ignore`** anywhere in the canonical config. The only
  `disable_error_code` override is scoped to pydantic model modules (a known
  pydantic-v2 + mypy false positive on data-schema classes).

### Linting (ruff)

- `preview = true` — enables the latest preview rules.
- Broad rule selection: `E, W, F, I, N, UP, B, C4, SIM, PTH, RUF, ANN, S, PL,
  TID, PT, TRY, DTZ`.
- **No `noqa` directives** in the canonical config.
- `per-file-ignores` for tests allows only `S101` (assert) and `PLR2004`
  (magic values) — standard test practice, not an escape hatch.

### Testing (pytest)

- `--strict-markers --strict-config` — no silent typos in marker names.
- `pytest-socket` — blocks accidental network calls (disable per-test with
  `@pytest.mark.network`).
- `hypothesis` — property-based testing support.

### Coverage

- `branch = true` — tracks branch coverage, not just line coverage.
- Excludes `if TYPE_CHECKING:` guards and `...` protocol stubs.

## What was stripped (vs. the source)

- Project name (`aeolist`), description, entry-point scripts.
- `src/aeolist/models/signals.py = ["PLC0415"]` — a project-specific
  cycle-break import override.
- `tests/conftest.py = ["RUF076"]` — a project-specific autouse-fixture scope.
- The `RUF069` test ignore (project-specific deterministic-fraction comparisons).
- Detailed inline comments tied to specific pipeline stages.

## What is NOT here

- **Dependencies** — add your own.
- **CI workflow** — see this repo's planning docs for CI guidance.
