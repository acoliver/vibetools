# Plan Review Prompt

Use this prompt to have an AI agent rigorously review a multi-phase implementation
plan before execution. Fill in the placeholder paths and issue number for your
project.

---

You are reviewing a multi-phase implementation PLAN (documentation only, no
production code yet) for a feature in this project. Read every plan artifact
under the plan directory.

## Your task

Perform a rigorous, complete review of the PLAN for correctness, executability,
and standards compliance. Determine whether this plan, if executed exactly as
written, would produce a correct, high-quality, standards-compliant
implementation.

## Authoritative reference materials (read these)

- The feature requirements: the GitHub issue or spec this plan implements.
- The standards the plan must enforce (fill in your project's paths):
  - `<PLAN.md>` — the planning methodology.
  - `<PLAN-TEMPLATE.md>` — the plan structure template.
  - `<COORDINATING.md>` — phase coordination rules.
  - `<RULES.md>` — language-specific development rules.
  - `<standards docs>` — any additional coding/architecture standards.
- The current source tree — verify the plan's claimed integration points (file
  paths, function names, line numbers, module structure) actually match the
  current code.

## Review dimensions (all must hold)

1. **Requirement completeness:** every part of the issue scope is covered by an
   expanded, testable requirement with GIVEN/WHEN/THEN behavior contracts. No
   scope gaps.
2. **Codebase accuracy:** claimed files/functions/line numbers/enums/modules
   exist as described. Flag any stale or wrong references.
3. **Architecture & boundaries:** additive (no parallel `*_v2` forks); respects
   module ownership; no circular dependencies.
4. **TDD discipline:** strict Stub → TDD(RED) → Impl(GREEN) per slice; tests
   verify behavior not internals; no mock theater; RED genuinely fails before
   GREEN.
5. **Phase coordination:** strict sequential numbering with paired worker +
   verifier phases; prerequisite gates; completion markers; verifier output
   contract requires behavioral evidence (cited file:line), runtime-path
   reachability, contradiction scans, atomic PASS/FAIL.
6. **Traceability:** per-file markers; impl phases cite pseudocode line ranges;
   requirement-to-phase-to-pseudocode matrix is complete and consistent.
7. **Pseudocode quality:** numbered, algorithmic, with validation/error/ordering/
   side-effects; impl phases reference real line ranges that exist in the
   pseudocode files.
8. **Quality gates:** every phase declares the verification baseline (lint,
   complexity, build, test, plus the suppression-allow gate). Deferred-
   implementation grep gates present in impl phases.
9. **Hard constraint — no overrides:** the plan must forbid any suppression
   directive (`eslint-disable`, `ts-ignore`, `#[allow(...)]`, `noqa`, etc.) and
   must forbid raising any complexity/size threshold. The plan must require
   functions/modules be split small enough to satisfy thresholds without
   overrides. Verify this is enforced in the verification phases.
10. **Regression avoidance:** known bugs in related features are explicitly
    addressed by a named requirement AND a verification check.
11. **Integration & access path:** explicit who-calls-what, user trigger path,
    state migration, backward-compatibility.
12. **Internal consistency:** file cross-references, phase numbering,
    traceability matrix, and execution tracker are mutually consistent; no
    contradictions; no missing referenced files.

## Output format (required)

- A verdict line: exactly `REVIEW VERDICT: PASS` or `REVIEW VERDICT: FAIL`.
  - PASS only if the plan is executable and standards-compliant with at most
    pedantic/cosmetic nits remaining.
  - FAIL if there is any substantive defect: scope gap, wrong/stale codebase
    reference, broken TDD/coordination, missing regression guard, missing/weak
    quality gate, or any path that permits suppression/complexity overrides.
- A numbered list of findings. For each: severity (BLOCKER / MAJOR / MINOR /
  PEDANTIC), the exact file and section, what is wrong, and a concrete required
  correction. Cite file:line evidence from the plan and/or current source where
  relevant.
- If PASS, still list any remaining PEDANTIC nits.

Be thorough and skeptical. Ground every finding in evidence from the actual
files.
