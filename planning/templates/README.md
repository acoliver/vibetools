# Planning Templates

A semi-agentic, human-in-the-loop planning system for shipping features with AI
coding agents. It produces measurably better results than ad-hoc prompting by
enforcing a strict phase structure: architect specification, preflight
verification, analysis, pseudocode, TDD cycles, integration, and semantic
verification.

## How it works

The system splits work into **numbered phases** executed sequentially by worker
agents, with verification after each phase. Each phase is isolated: one phase
gets one worker, one verifier. No skipping, no batching.

The phase lifecycle for a feature:

```
Phase 0    Architect specification (specification.md)
Phase 0.5  Preflight verification (verify all assumptions before coding)
Phase 1    Analysis (break down the problem)
Phase 2    Pseudocode (line-numbered blueprint)
Phase 2.5  Integration contract definition (for multi-component features)
Phase 3+   Implementation cycles: Stub -> TDD -> Implementation -> Verify
Phase N    Integration + end-to-end verification
```

## Structure

```
planning/templates/
  _base/
    PLAN.md            The methodology: how to create plans, phase structure,
                       fraud detection, verification gates
    PLAN-TEMPLATE.md   The fill-in template for generating a plan
    COORDINATING.md    How to coordinate worker agents to execute a plan
  rust/
    RULES.md           Development rules for Rust projects
  typescript/
    RULES.md           Development rules for TypeScript projects
  python/
    RULES.md           Development rules for Python projects
```

The three `_base/` docs are language-agnostic. The per-language `RULES.md` files
contain the language-specific development rules (TDD tooling, linting, typing,
testing frameworks, verification commands).

## How to use this

1. **Copy the templates into your project.** Copy `_base/` into your project's
   `dev-docs/` or `project-plans/` directory.
2. **Pick the matching language rules.** Copy the `RULES.md` from the matching
   language directory (`rust/`, `typescript/`, or `python/`) alongside the base
   docs.
3. **Create a plan.** Follow `PLAN.md` to create an architect specification, then
   use `PLAN-TEMPLATE.md` to generate the phased plan.
4. **Execute the plan.** Follow `COORDINATING.md` to drive worker agents through
   each phase sequentially, verifying after each one.

### Pointing an agent at this

To tell an AI agent to plan work on a project:

> Use the planning templates in `dev-docs/` to create a phased plan. Read
> `PLAN.md` for the methodology, `RULES.md` for the development rules, and
> `PLAN-TEMPLATE.md` for the plan structure. Create the plan in
> `project-plans/<feature>/`.

## Origin

Ported from the llxprt-code planning system and adapted from Rust (jefe, luther)
and Python (aesop) variants. De-repo-ified: all project-specific paths, feature
names, and tool-specific commands have been generalized. The methodology is
tool-agnostic (works with any agent that supports subagent delegation), though
references to specific agent tools are preserved where the coordination pattern
depends on them.
