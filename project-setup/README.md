# Project setup (lint / complexity / config)

Canonical, language-specific **lint / complexity / formatting / type-check**
configs, coalesced from several production projects into one place so
bootstrapping a new project's quality bar is a single command.

Each language directory contains the canonical config files plus an `init.sh`
installer that copies them into a target project and fills in the
non-portable bits (project name, paths).

## What's here

| Language | Location | Sources coalesced |
| --- | --- | --- |
| **Rust** | [`rust/`](rust/) | jefe, luther, personal-agent |
| **TypeScript** | [`typescript/`](typescript/) | llxprt-code (production codebase) |
| **Python** | [`python/`](python/) | aesop (production codebase) |

## Quick start

The universal launcher delegates to the per-language installer:

```sh
# From anywhere:
project-setup/setup.sh <language> [target-dir] [package-name]

# Examples — run from your project root:
project-setup/setup.sh rust .
project-setup/setup.sh typescript .
project-setup/setup.sh python . my_package
```

Or call a language installer directly:

```sh
project-setup/rust/init.sh .
project-setup/typescript/init.sh .
project-setup/python/init.sh . my_package
```

Each installer prints the exact next steps (install deps, run linters).

## Rule-selection policy

These configs follow one rule: **pick the strictest option; never loosen.**

- Wherever two source projects disagree on a threshold, the **lower / stricter**
  value wins.
- **No suppression directives** in any canonical config — no `eslint-disable`,
  no `#[allow(...)]`, no `noqa`, no `ts-ignore`, no `type: ignore`. Fix the
  underlying issue instead.
- Complexity/size thresholds are never raised.

The Rust setup is the clearest example of coalescing: three projects with
drifting, slightly-different clippy configs merged into one, taking the
strictest of each. See [`rust/README.md`](rust/README.md) for the full
rule-by-rule rationale.

## How this fits with the planning system

The [`planning/templates/`](../planning/templates/) language RULES docs
reference these configs as the concrete quality bar. When you set up a new
project:

1. **Plan** — copy `planning/templates/<language>/` + `_base/` docs.
2. **Configure** — run `project-setup/setup.sh <language> .` to install
   lint/complexity gates.
3. **Build** — follow the plan with the quality bar already in place.

## Pointing an agent here

To have an AI agent set up linting for a new project:

> Copy the lint/complexity config from `vibetools/project-setup/<language>/`
> into this project by running its `init.sh`, then verify the linters pass
> before writing any code.
