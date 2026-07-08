# Deno project setup

Canonical Deno **lint / format / typecheck / test** config, using Deno's
built-in toolchain (`deno lint`, `deno fmt`, `deno check`, `deno test`).
No external dependencies required — everything ships with the Deno runtime.

**Assumes Deno 2.x.**

## Files

| File | Purpose |
| --- | --- |
| `deno.json` | Single config: compilerOptions, lint rules, fmt settings, test paths, tasks, import map. |
| `init.sh` | One-command installer — copies `deno.json` into the target project. |

## Why Deno's built-in tools?

Deno ships with a linter, formatter, type checker, and test runner — no
`npm install` needed. This is the simplest possible setup: one file (`deno.json`)
configures everything, and `deno task ci` runs the full quality gate.

## Lint rules

The config enables the `recommended` tag plus these additional rules:

| Rule | What it catches |
| --- | --- |
| `ban-untagged-todo` | `// TODO` without an assignee |
| `no-await-in-loop` | Sequential awaits that could be parallelized |
| `no-external-import` | Bare specifiers (use `jsr:` or `npm:` explicitly) |
| `no-sloppy-equality` | `==` / `!=` (use `===` / `!==`) |
| `prefer-ascii` | Non-ASCII characters in identifiers/strings |
| `no-node-globals` | Node.js globals (`__dirname`, `require`, `process`) — use Deno APIs |

## Formatting

Matches the TypeScript and Bun templates:

| Setting | Value |
| --- | --- |
| Line width | 80 |
| Indent width | 2 spaces |
| Semicolons | Always |
| Single quotes | Yes |
| Prose wrap | Preserve |

## Type checking

The `compilerOptions` enable all `strict` family flags (same as the TypeScript
template). Deno's built-in type checker runs via `deno check`.

## Testing

Uses `deno test` (Deno's built-in test runner). The `deno.json` `test` section
includes `src/` and excludes test fixtures.

```bash
deno test                 # run tests
deno test --coverage      # run with coverage
```

## Tasks

The `deno.json` defines convenience tasks:

```bash
deno task lint            # deno lint
deno task fmt             # deno fmt (write)
deno task fmt:check       # deno fmt --check (CI mode)
deno task check           # deno check src/ (typecheck)
deno task test            # deno test --allow-all
deno task ci              # fmt --check + lint + check + test
```

## Rule gaps vs the ESLint template

Deno's linter is intentionally simpler than ESLint. The following are **not
available** as built-in Deno lint rules:

| ESLint rule | What it catches | Deno status |
| --- | --- | --- |
| `complexity` (15) | Cyclomatic complexity | Not available |
| `max-lines` (800) | File length | Not available |
| `max-lines-per-function` (80) | Function length | Not available |
| `sonarjs/cognitive-complexity` (30) | Cognitive complexity | Not available |
| `@typescript-eslint/no-floating-promises` | Unhandled promises | Not available |
| `@typescript-eslint/strict-boolean-expressions` | Implicit coercion | Not available |
| `no-console` | Console output | Not available |

Deno's recommended ruleset focuses on correctness and Deno-specific best
practices rather than complexity gates. If complexity enforcement is critical
for your project, consider using the `project-setup/bun/` template (Biome's
`noExcessiveCognitiveComplexity`) or the `project-setup/typescript/` template
(ESLint with full complexity rules).

## Quick start

```bash
./init.sh /path/to/project
cd /path/to/project
deno task ci
```
