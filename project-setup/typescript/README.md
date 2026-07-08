# TypeScript project setup

Canonical TypeScript **lint / complexity / formatting** config, distilled from a
mature production codebase (flat config, ESLint 9+, `typescript-eslint`).

The source config was heavily customized with monorepo paths, package-specific
imports, custom ESLint rules, React/Ink internals, and issue-specific size
enforcement. This template strips all of that, keeping only the **portable core
rules** so it drops into any TypeScript project.

## Files

| File | Purpose |
| --- | --- |
| `eslint.config.js` | Flat ESLint config: strict TS rules, complexity gates, SonarJS, import, eslint-comments. |
| `tsconfig.json` | Strict `compilerOptions` (all `strict` family flags, NodeNext modules). |
| `.prettierrc.json` | Prettier formatting (single quotes, trailing comma, 80-col). |
| `package.devdeps.json` | DevDependencies + recommended npm scripts to merge into `package.json`. |
| `init.sh` | One-command installer — copies the configs and prints next steps. |

## Quick start

```sh
# From the root of your TypeScript project:
path/to/vibetools/project-setup/typescript/init.sh .

# Or via the universal launcher:
path/to/vibetools/project-setup/setup.sh typescript .
```

Then install the dev dependencies and verify:

```sh
npm install -D eslint typescript-eslint eslint-config-prettier \
  eslint-plugin-import eslint-plugin-sonarjs eslint-plugin-eslint-comments \
  globals prettier typescript

npx eslint . --max-warnings 0
npx prettier --check .
npx tsc --noEmit
```

## Why these rules

This is a **single-source** setup (one production codebase), so the values are
kept as-is — there were no conflicts to resolve. Key design decisions:

### Complexity limits

| Rule | Value | Notes |
| --- | --- | --- |
| `complexity` | **15** | Cyclomatic complexity per function. |
| `max-lines` | **800** | Max lines per file (skips blanks/comments). |
| `max-lines-per-function` | **80** | Max lines per function (relaxed to off in test files). |
| `sonarjs/cognitive-complexity` | **30** | Cognitive complexity per function. |

All are set to `warn`, but the recommended `lint` script uses
`--max-warnings 0`, making them **effective errors** in CI. Never raise these
thresholds or downgrade `warn` → `off`.

### Notable strict rules

- `@typescript-eslint/no-explicit-any` — **error** (no `any`).
- `@typescript-eslint/no-floating-promises` / `await-thenable` — **error**
  (no unhandled async).
- `@typescript-eslint/no-unused-vars` — ignores only `_`-prefixed names.
- `@typescript-eslint/strict-boolean-expressions` — no truthy `0`/`""` gotchas.
- `no-console` — **warn** (use a logger in libraries).
- `import/no-relative-packages`, `no-var`, `prefer-const`, `eqeqeq` — enforced.

### Policy: no suppression directives

This config contains **zero** `eslint-disable` comments and no `ignores:`
block that excludes source from linting (only build artifacts are ignored).
Do not add them — fix the underlying issue instead.

### Optional plugins

React and Vitest rules are included but **commented out** so the config works
out-of-the-box for plain Node/CLI projects. Uncomment the marked blocks (and
install the deps) to activate them.

## What was stripped (vs. the source)

- Monorepo `files: ['packages/...']` targeting → now applies to all `**/*.{ts,tsx}`.
- Custom ESLint rules (`react-render-safety`, `no-inline-deps`, `ink-text-color-required`).
- Issue-specific per-file enforcement (buffer/text-buffer/subagent decomposition blocks).
- Provider-auth anti-pattern rules (project-specific).
- Library-specific `no-restricted-imports` for internal package names.

## What is NOT here

- **Dependencies** — add your own.
- **CI workflow** — see this repo's planning docs for CI guidance.
