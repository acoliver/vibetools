# Bun project setup

Canonical Bun **lint / complexity / formatting** config, using [Biome](https://biomejs.dev)
as the single toolchain (replaces ESLint + Prettier) and `bun test` as the
test runner.

**Assumes Bun 1.1+.** Add `"engines": { "bun": ">=1.1.0" }` to your `package.json`.

## Why Biome instead of ESLint?

Biome is the Bun-native toolchain: one tool for linting, formatting, and import
sorting, with zero external plugins. It is 10-50x faster than ESLint+Prettier
and requires only one devDependency (`@biomejs/biome`).

The trade-off: Biome does not have the full ESLint plugin ecosystem (no SonarJS,
no `eslint-plugin-import` internals, no `eslint-comments`). The key complexity
gate — `noExcessiveCognitiveComplexity` (max 15) — is available and maps directly
to the ESLint template's `sonarjs/cognitive-complexity` rule. See
[Rule gaps](#rule-gaps-vs-the-eslint-template) below.

## Files

| File | Purpose |
| --- | --- |
| `biome.json` | Biome config: all recommended rules + strict complexity/type-safety overrides. |
| `tsconfig.json` | Strict `compilerOptions` for Bun (`bun-types`, ESNext, bundler resolution). |
| `bunfig.toml` | Bun test runner config (coverage, threshold 80%). |
| `package.devdeps.json` | DevDependencies + recommended bun scripts. |
| `init.sh` | One-command installer — copies the configs and prints next steps. |

## Complexity limits

| Metric | Limit | Biome rule |
| --- | --- | --- |
| Cognitive complexity per function | 15 | `complexity/noExcessiveCognitiveComplexity` |
| Unused variables/imports | error | `correctness/noUnusedVariables`, `noUnusedImports` |
| Explicit `any` | error | `suspicious/noExplicitAny` |
| Empty block statements | error | `suspicious/noEmptyBlockStatements` |
| `console.*` in source | warn | `suspicious/noConsole` (off in tests) |

## Formatting

Biome's formatter replaces Prettier. Settings match the TypeScript template:

| Setting | Value |
| --- | --- |
| Indent style | 2 spaces |
| Line width | 80 |
| Quote style | Single quotes |
| Semicolons | Always |
| Trailing commas | All |
| Arrow parentheses | Always |

## Testing

Uses `bun test` (Bun's built-in Jest-compatible test runner). The `bunfig.toml`
configures coverage at an 80% threshold with text + lcov output.

```bash
bun test                # run tests
bun test --coverage     # run with coverage
```

## Rule gaps vs the ESLint template

The following ESLint rules have **no direct Biome equivalent** and are documented
here for transparency:

| ESLint rule | What it catches | Biome status |
| --- | --- | --- |
| `max-lines` (800) | File length | Not available |
| `max-lines-per-function` (80) | Function length | Not available |
| `sonarjs/cognitive-complexity` (30) | Cognitive complexity | **Available** as `noExcessiveCognitiveComplexity` (15, stricter) |
| `@typescript-eslint/no-floating-promises` | Unhandled promises | Partially covered by `suspicious/noMisusedPromises` |
| `@typescript-eslint/strict-boolean-expressions` | Implicit null/0/'' coercion | Not available |
| `import/no-internal-modules` | Deep import paths | Not available |
| `eslint-comments/*` | Comment-based disables | Biome tracks suppressions natively |

If any of these are critical for your project, use the `project-setup/typescript/`
template instead and install `@biomejs/biome` only as a formatter.

## Quick start

```bash
./init.sh /path/to/project
cd /path/to/project
bun add -d @biomejs/biome bun-types typescript
bunx biome check .
```
