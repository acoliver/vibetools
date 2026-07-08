# Autonomous Plan-Creation Guide

This document defines how to create foolproof implementation plans that prevent
AI-agent fraud and ensure valid TDD implementations through autonomous worker
execution.

When executing plans, follow the coordination rules in
[COORDINATING.md](./COORDINATING.md) and use the
[PLAN-TEMPLATE.md](./PLAN-TEMPLATE.md) for generating plans.

Language-specific development rules live in the matching `RULES.md` for your
language (see the parent [README.md](../README.md)).

---

## Core Principles

1. **TDD is mandatory** - Every line of production code is written in response
   to a failing test.
2. **Worker isolation** - Each phase is executed by a fresh worker instance with
   clean context.
3. **Architect-first** - All plans begin with an architect-written specification.
4. **Analysis before code** - Mandatory analysis/pseudocode phases before
   implementation.
5. **Aggressive verification** - Multi-layered fraud detection at every step.
6. **No reverse testing** - Tests never check for NotYetImplemented or stub
   behavior.
7. **Modify, don't duplicate** - Always update existing files, never create
   parallel versions.
8. **No isolated features** - Every feature must be integrated into the existing
   system, not built in isolation.
9. **Integration-first testing** - Integration tests are written before unit
   tests to verify component contracts.
10. **Preflight verification** - All assumptions are verified before
    implementation begins.
11. **Semantic over structural** - Verify features work, not just that files and
    markers exist.

---

## Phase Numbering and Execution

### Sequential execution is mandatory

Phases must be executed in exact numerical sequence. Skipping phase numbers is
the single most common coordination failure.

Rules:

1. **Never skip numbers** - Phases run P03, P04, P05, P06, ... not P03, P06, P09.
2. **Use plan IDs** - Every plan gets a `PLAN-YYYYMMDD-FEATURE` ID.
3. **Tag everything** - Every implementation includes `@plan:PLAN-ID.P##` markers.

### Required plan structure

```
Plan ID: PLAN-YYYYMMDD-FEATURE
Phases: 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16

Execution MUST be sequential:
  P03 -> Verify -> P04 -> Verify -> P05 -> Verify -> ...
NEVER: P03 -> P06 -> P09 -> P16 (skipped phases)
```

### Code traceability requirements

Every function, test, and class must include plan and requirement markers in its
docstring/comment header:

```
@plan PLAN-YYYYMMDD-FEATURE.P07
@requirement REQ-003.1
```

### Phase verification before proceeding

Before starting any phase after P03, verify the previous phase exists:

```bash
# Check previous phase markers exist
grep -rn "@plan:PLAN-YYYYMMDD-FEATURE.P[NN-1]" .
# If missing, the previous phase was not completed - STOP
```

---

## Critical: Integration Requirements

### The problem agents keep repeating

Agents build features in complete isolation: they create new files, write tests
for those files, and declare success. But the feature is never connected to the
existing system. It compiles, its tests pass, and it is completely unreachable
by any user.

This is the most critical failure mode. A feature that works in isolation but is
not integrated is useless.

### Mandatory integration analysis

Every plan MUST include an Integration Points section identifying:

1. **Existing code that will use this feature** - specific files and functions.
2. **Existing code to be replaced** - what old code gets removed.
3. **User access points** - how a user actually triggers the feature.
4. **Migration requirements** - what happens to existing data/state.

If a feature can be built without modifying ANY existing files (except exports),
**reject the plan**.

### Integration checklist

- [ ] Plan lists specific existing files that will call/use the feature.
- [ ] Plan identifies exact old code to be replaced or removed.
- [ ] Plan shows the user-facing entry point (CLI command, UI action, API route).
- [ ] Plan includes dedicated integration phases (not just unit tests).
- [ ] Feature CANNOT work without modifying existing files.

---

## Phase 0: Architect Specification (specification.md)

Before any implementation planning, write a specification document. This is
written by the architect (human or lead agent), not by implementation workers.

### Required sections

```markdown
# Feature Specification: <Name>

## Purpose
[What problem this solves and why it matters]

## Architectural Decisions
[Key design decisions and their rationale]

## Project Structure
[Where new code goes and how it fits the existing layout]

## Technical Environment
[Language version, key dependencies, build/test commands]

## Integration Points (MANDATORY)
### Existing code that will use this feature
[Specific files and functions]
### Existing code to be replaced
[What old code gets removed]
### User access points
[How users trigger this feature]
### Migration requirements
[Data/state migration if applicable]

## Formal Requirements
[Numbered requirements: REQ-001, REQ-002, ...]

## Data Schemas
[Types/models/interfaces this feature introduces or modifies]

## Constraints
[Performance, security, compatibility constraints]

## Performance Requirements
[If applicable]
```

---

## Phase 0.5: Preflight Verification (MANDATORY)

### Why this phase exists

Plans are written based on assumptions about the existing codebase: that
dependencies exist, types match expectations, call paths are possible, and test
infrastructure is in place. If any assumption is wrong, every subsequent phase
builds on a false foundation. This phase verifies every assumption before a
single line of code is written.

### Required verifications

1. **Dependency verification** - For each library/dependency the plan references,
   verify it is installed and the version matches expectations.

2. **Type/interface verification** - For each type referenced in the plan, verify
   it exists and its definition matches what the plan assumes (field names,
   signatures, return types).

3. **Call-path verification** - For each function the plan says will be called or
   modified, verify the code path described actually exists. Where is it called
   from? What does it return? What parameters does it take?

4. **Test infrastructure verification** - Verify test files exist for components
   being modified, test patterns work, and the test framework is set up.

### Preflight verification results

```markdown
# Phase 0.5: Preflight Verification Results

## Dependencies Verified
| Dependency | Installed? | Version | Status |

## Types Verified
| Type | Expected | Actual | Match? |

## Call Paths Verified
| Function | Expected Caller | Actual | Evidence |

## Test Infrastructure Verified
| Component | Test File? | Patterns Work? |

## Blocking Issues Found
[List issues that MUST be resolved before proceeding]
```

### Verification gate

If ANY checkbox is unchecked, STOP. Fix the plan before proceeding to
implementation. Do not "come back to it later."

---

## Phase 1: Analysis Phase

A worker agent analyzes the domain and breaks down the problem.

**Worker task**: Read the specification, identify the components involved, map
data flows, and produce a domain analysis document.

**Verification checks**:
- All requirements from the specification are addressed.
- All components and their interactions are identified.
- Integration points with existing code are documented.

---

## Phase 2: Pseudocode Phase

A worker creates line-numbered pseudocode for each component.

### Pseudocode MUST be used

Pseudocode is not optional decoration. It is the blueprint that implementation
must follow line by line. Implementation phases must reference specific
pseudocode line numbers, and verification must confirm compliance.

```
# WRONG: Pseudocode ignored
"Implement the feature according to the analysis"

# CORRECT: Pseudocode enforced
"Implement following pseudocode lines 11-45 from analysis/pseudocode/component.md"
```

**Worker task**: Create detailed, line-numbered pseudocode for every component.
Each line describes one atomic step.

**Verification checks**:
- Pseudocode has line numbers.
- Every requirement is addressed in the pseudocode.
- Integration steps are included (how the component connects to existing code).

### Contract-first pseudocode requirements

For multi-component features, pseudocode must define the contract between
components before describing internal logic:

1. What data does Component A pass to Component B?
2. What does Component B return?
3. What errors can propagate?
4. What side effects occur?

---

## Phase 2.5: Integration Contract Definition (RECOMMENDED for multi-component features)

Before implementation cycles begin, define the contracts between components.

### Required artifacts

1. **Component interface definitions** - signatures, inputs, outputs.
2. **Data flow diagram** - how data moves between components.
3. **Error propagation rules** - how errors flow between components.
4. **Integration test specification** - what the integration test will verify.

This phase ensures that when components are implemented independently, they will
connect correctly because the contract was agreed before any implementation.

---

## Phase 3+: Implementation Cycles

Each feature component follows a three-phase cycle: Stub, TDD, Implementation.
Each phase gets its own worker and its own verifier.

### A. Stub Phase

Create the minimal structure that compiles/type-checks but does not implement
logic.

**Rules**:
- Stubs may return empty values or throw NotImplementedError.
- Stubs MUST compile and be importable.
- Tests MUST NOT expect or catch NotImplementedError (no reverse testing).
- Files are updated, not duplicated.

**Verification checks**:
- Stubs compile/type-check.
- No TODO comments (NotYetImplemented is acceptable in stubs only).
- No version duplication (no `ServiceV2`, `ServiceNew`).
- Tests, if written, fail naturally when encountering stubs (not with
  NotImplementedError errors).

### B. TDD Phase

Write failing behavioral tests for the component.

**Rules**:
- Tests expect real behavior (input to output), not stub behavior.
- No reverse tests (never `expect(() => fn()).toThrow('NotImplemented')`).
- Tests assert actual values (equality, matching), not just structure
  (existence, defined).
- At least 30% property-based tests where the framework supports it.
- Integration tests are defined before unit tests.

**Verification checks**:
- Tests assert behavioral outputs, not structure.
- No mock theater (tests that only verify mocks were called).
- No reverse testing (tests that expect NotImplementedError).
- Tests would fail if the implementation were removed.
- Behavioral assertions present (equality/matching, not just existence checks).

### C. Implementation Phase

Write the production code that makes all tests pass, following the pseudocode
exactly.

**Rules**:
- Follow pseudocode line-by-line.
- Do not modify any existing tests.
- Update existing files (no new versions).
- Reference pseudocode line numbers in comments.
- No debug code, no TODO/FIXME comments.
- No placeholder or hollow implementations.

**Verification checks**:
- All tests pass.
- No test modifications (git diff on test files is empty).
- Pseudocode was followed (every numbered line implemented).
- No debug code (console output, TODO, FIXME).
- No duplicate files (no `*V2`, `*Copy`, `*New`).
- Deferred implementation detection passes (see below).

---

## Advanced Verification: Fraud Detection

### Deferred implementation detection

An agent may appear to implement a feature but actually defer the real work.

Search the implementation for these deferral markers:
- `NotImplemented` / `NotYetImplemented`
- `TODO` / `FIXME` / `HACK` / `XXX`
- `pass` / `// stub` / placeholder return values
- Methods that return empty collections or default values without logic
- `unimplemented!()` / `todo!()` / `panic!("not yet")`

**Rule**: Every `NotImplemented`/equivalent MUST be justified and mapped to a
future phase. If a required behavior has no real implementation, the phase is
INCOMPLETE, not DONE.

### Hollow implementation detection

An implementation may compile, pass tests, and appear complete while doing
nothing real.

**Red flags**:
- Methods that return immediately with a constant or empty value.
- Methods that log or print but never persist state or return meaningful data.
- Methods that call other stubs (stub calling a stub).
- Branches that are never reached because earlier branches always match.
- Tests that pass regardless of input (always-true assertions).

**Detection**: For every public method, ask: "If I deleted the body and returned
a default value, would ANY test fail?" If not, the implementation is hollow and
the tests are insufficient.

### Test-validity verification

Tests can pass for the wrong reasons. Verify tests are actually exercising
real behavior:

1. **Remove the implementation** - Does the test still pass? If yes, the test is
   broken (it is not exercising the feature at all).
2. **Invert the assertion** - Flip equality checks (`==` to `!=`). Does the test
   fail? If not, the assertion is meaningless.
3. **Mock dependency check** - Are ALL dependencies mocked? Then the test is
   mock theater, not behavioral testing.
4. **Partial input coverage** - Does the test only use one input? Real behavior
   tests use multiple inputs including edge cases and property-based tests.

---

## Semantic Verification Checklist

Semantic verification means: does the feature actually do what it should, from
the user's perspective, using the real system (not mocks)?

### The semantic verification questions

For every feature, before marking it complete, answer these questions with
evidence:

1. **Traceability** - Can you point to the exact code that implements each
   requirement?
2. **Reachability** - Can a user actually reach this feature through a real
   entry point? What is the path?
3. **Behavioral evidence** - Is there a test that proves the correct output is
   produced for a given input (not just that no error is thrown)?
4. **Integration evidence** - Does an integration test show the feature working
   with real dependencies (database, network, file system) rather than mocks?
5. **Removal test** - If you deleted the implementation, would any test fail?
6. **Falsification** - Would the test fail if the implementation returned the
   wrong answer instead of the right one?

If you cannot answer "yes" with evidence for each, the feature is not verified.

### Verification atomicity

Verification must be an atomic gate: ALL checks must pass, or the phase fails.
Partial verification is not verification. One failed check blocks the entire
phase.

---

## Vertical Slice Testing

### The vertical slice principle

A feature is complete only when a user can exercise the full path: entry point
through all layers to the final result, using real (not mocked) components.

A "vertical slice" test verifies one complete path end-to-end:

```
User Action -> Entry Point -> Processing -> Data Layer -> Result -> User Sees Result
```

### When to use vertical slice tests

- After all unit tests pass, write at least one vertical slice test per feature.
- The slice must use the real system (real database connection, real file I/O,
  real network if applicable) — not mocks.
- If the feature cannot be exercised end-to-end without mocks, that signals the
  architecture needs integration points added.

### Vertical slice checklist

- [ ] At least one test exercises the full path from entry point to result.
- [ ] The test uses real dependencies (no mocks for the components under test).
- [ ] The test asserts the final observable output the user would see.
- [ ] The test would fail if any layer in the path were removed or broken.

---

## Plan Evaluation Checklist

Before approving any plan, verify every item:

### Structure
- [ ] Plan ID is set (PLAN-YYYYMMDD-FEATURE).
- [ ] Phases are numbered sequentially with no gaps.
- [ ] Phase 0 (specification) is complete before any implementation phases.
- [ ] Phase 0.5 (preflight) verifies all assumptions.
- [ ] Each component has Stub, TDD, and Implementation phases.

### Integration
- [ ] Integration Points section identifies existing files that will be modified.
- [ ] The feature CANNOT be built without modifying existing files.
- [ ] A dedicated integration phase connects the feature to the system.
- [ ] At least one vertical slice test is planned.

### Anti-fraud
- [ ] Pseudocode is line-numbered and referenced by implementation phases.
- [ ] No reverse testing is allowed (tests do not expect NotImplementedError).
- [ ] Deferred implementation detection is included in verification.
- [ ] Hollow implementation detection is included in verification.
- [ ] Semantic verification questions are answerable with evidence.

### Quality
- [ ] Property-based tests are planned (30%+ where supported).
- [ ] Tests assert behavioral outputs (equality/matching), not just structure.
- [ ] No mock theater (tests that only verify mock calls).
- [ ] No suppression directives in the plan (no lint-disable, no type-ignore).

---

## Red Flags: Common Agent Failures

These patterns indicate an agent is cutting corners or faking completion:

1. **"Tests pass" with no behavioral assertions** - Tests check structure
   (existence, defined, length > 0) but never check actual values.

2. **All dependencies mocked** - The test verifies that mocks were called, not
   that the system produces correct results. This is mock theater.

3. **Reverse testing** - Tests that expect `NotImplementedError` or stub
   behavior. These tests PASS when the feature is incomplete and FAIL when it is
   done — the opposite of what you want.

4. **Skipped phases** - The plan has P03, P04, P07, P12. Phases P05, P06 were
   skipped. This means work was done out of order or skipped entirely.

5. **New files instead of modifications** - `FeatureV2.ts` exists alongside
   `Feature.ts`. The agent duplicated instead of modifying, leaving dead code.

6. **"Integrated" but unreachable** - The feature compiles and tests pass, but no
   existing code calls it. A user can never trigger it.

7. **Hollow implementations** - Methods return empty/default values. Tests pass
   because they only check that no error is thrown, not that output is correct.

8. **Debug code left in** - console output, TODO comments, commented-out code.

9. **Modified tests** - The agent changed existing tests to make them pass
   instead of fixing the implementation. Git diff on test files should be empty
   during implementation phases.

10. **Pseudocode ignored** - The plan has detailed pseudocode, but the
    implementation does not reference it and follows a different structure.

---

## Success Metrics

A plan has succeeded when ALL of the following are true:

- Every requirement from the specification has corresponding passing tests.
- At least one vertical slice test exercises the feature end-to-end.
- No `NotImplemented`/`TODO`/`FIXME` markers remain in production code.
- No suppression directives (lint-disable, type-ignore) were added.
- `git diff` shows modifications to existing files (integration), not just new
  files.
- Removing any implementation function would cause at least one test to fail.
- A user can reach the feature through a real entry point and observe correct
  behavior.

---

## Quick Reference: Plan Structure

```
P0    Architect Specification     (written before planning)
P0.5  Preflight Verification      (verify all assumptions)
P1    Analysis                    (domain breakdown)
P2    Pseudocode                  (line-numbered blueprint)
P2.5  Integration Contract        (multi-component only)
---
For each component:
P_N     Stub                      (compiles, no logic)
P_N+1   TDD                       (failing behavioral tests)
P_N+2   Implementation            (make tests pass)
---
P_Last Integration                (connect to existing system)
P_Last Vertical Slice             (end-to-end, real deps)
P_Last Verification               (semantic + fraud detection)
```

Every phase: Worker implements -> Verifier checks -> Gate passes/fails.
No phase proceeds until the previous phase passes its gate.
