# vibetools

A **shared playbook for vibe coding** — a single home for the writing styleguides,
planning systems, and lint/project setups I keep re-deriving in every new project.

The goal is simple: instead of rebuilding quality bars, planning workflows, and
writing conventions from scratch each time, they live here as portable templates
and configs. Point a human — or an AI agent — at this repo to bootstrap a new
project consistently.

## What's here (and what's coming)

This repo is being built out as a set of focused areas. Each area is tracked by an
issue so the work and the rationale stay visible.

| Area | Location | Status / Tracking |
| --- | --- | --- |
| **Writing styleguide** | `docs/writing/styleguide.md` | Available — see #2 |
| **Planning system** (language-parameterized) | `planning/templates/{language}/` | Available — see #3 |
| **Project setup** (lint/complexity/configs) | `project-setup/{language}/` | Available — see #4 |
| **Bun & Deno templates** | `project-setup/{bun,deno}/` | Available — see #9 |

Existing reference notes in `docs/` (`TYPESCRIPT_STANDARDS.md`, `TESTING_GUIDE.md`,
`MOCKING_STRATEGY.md`) are retained as source material and will be folded into the
language-specific setups above as that work lands.

## How to use this to set up a new project

Once the areas above are in place, bootstrapping a new project is meant to be a
two-step pattern you can hand to an agent:

1. **Plan the work** — copy the planning docs from `planning/templates/<language>/`
   into the new repo and follow them.
2. **Set the quality bar** — install the matching lint/complexity config from
   `project-setup/<language>/` (a setup script fills in project-specific names).

Each area has its own README with exact usage once it's built out.

## Writing

A general-purpose writing styleguide lives at [`docs/writing/styleguide.md`](docs/writing/styleguide.md).
It was coalesced from project-specific styleguides and stripped of all domain,
client, and publication specifics so it applies to any non-fiction prose project.
Point a writer or agent at this file as the canonical writing styleguide.

## Planning

A portable, language-parameterized planning system lives at
[`planning/templates/`](planning/templates/). It was distilled from a mature
multi-phase TDD planning system and de-repo-ified so it works for any project.

**How it's organized:**

- [`planning/templates/_base/`](planning/templates/_base/) — language-agnostic docs
  shared by every language:
  - [`PLAN.md`](planning/templates/_base/PLAN.md) — the methodology (phases, TDD,
    integration, fraud detection, verification gates).
  - [`PLAN-TEMPLATE.md`](planning/templates/_base/PLAN-TEMPLATE.md) — fill-in-the-blanks
    structure for generating concrete plans.
  - [`COORDINATING.md`](planning/templates/_base/COORDINATING.md) — rules for
    executing a plan one phase at a time with isolated subagents.
- [`planning/templates/{rust,typescript,python}/RULES.md`](planning/templates/rust/RULES.md)
  — language-specific development rules (typing, testing, mocks, verification).

**To use it:** copy the three `_base/` docs plus the `RULES.md` for your language
into your project, then point an agent at `PLAN.md` and `COORDINATING.md`. See
[`planning/templates/README.md`](planning/templates/README.md) for full details.

> Note: this README describes the intended end state. The sections above are filled
> in as their tracking issues (#2, #3, #4) land. Anything that used to live here
> (`o3helper.js`, `workers.md`, the old `PLAN.md`, and `executor/`) has been removed
> as obsolete — see #1.

## Project setup

Canonical, language-specific **lint / complexity / formatting / type-check**
configs live at [`project-setup/`](project-setup/). They were coalesced from
several production projects and set to the **strictest** value wherever sources
disagreed.

**How it's organized:**

- [`project-setup/rust/`](project-setup/rust/) — clippy + rustfmt + Cargo lint
  policy, merged from jefe, luther, and personal-agent (strictest of each).
- [`project-setup/typescript/`](project-setup/typescript/) — ESLint flat config,
  tsconfig, Prettier, distilled from a mature production codebase (Node 24+).
- [`project-setup/bun/`](project-setup/bun/) — Biome (replaces ESLint+Prettier),
  bunfig.toml, tsconfig for Bun. Single-toolchain, 10-50x faster.
- [`project-setup/deno/`](project-setup/deno/) — Deno built-in lint/fmt/check/test.
  Zero external dependencies — everything ships with the Deno runtime.
- [`project-setup/python/`](project-setup/python/) — ruff + mypy + pytest +
  coverage config, distilled from a production Python codebase.

Each language has an `init.sh` installer, and a universal launcher ties them
together. To set up linting/complexity for a new project, run:

```sh
project-setup/setup.sh <language> .          # rust | typescript | bun | deno | python
```

See [`project-setup/README.md`](project-setup/README.md) for full details,
including the rule-by-rule rationale for how conflicts were resolved.

## License

See [LICENSE](LICENSE).
