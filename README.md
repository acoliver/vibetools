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
| **Writing styleguide** | `docs/writing/styleguide.md` | Planned — see #2 |
| **Planning system** (language-parameterized) | `planning/templates/{language}/` | Planned — see #3 |
| **Project setup** (lint/complexity/configs) | `project-setup/{language}/` | Planned — see #4 |

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

> Note: this README describes the intended end state. The sections above are filled
> in as their tracking issues (#2, #3, #4) land. Anything that used to live here
> (`o3helper.js`, `workers.md`, the old `PLAN.md`, and `executor/`) has been removed
> as obsolete — see #1.

## License

See [LICENSE](LICENSE).
