# Subagent Coordination Guide

## How to Execute Multi-Phase Plans

When you receive a plan with numbered phases, you MUST execute them
sequentially. This document explains HOW to coordinate subagents to implement
plans correctly.

Pair this with [PLAN.md](./PLAN.md) (methodology) and
[PLAN-TEMPLATE.md](./PLAN-TEMPLATE.md) (structure).

---

## The Golden Rules

1. **NEVER SKIP PHASE NUMBERS** - If you have phases 03-16, you MUST execute:
   03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16.
2. **ONE PHASE = ONE SUBAGENT** - Each phase gets exactly one subagent.
3. **VERIFY BEFORE PROCEEDING** - Each verification must pass before the next
   phase starts.
4. **NO COMBINING PHASES** - Phase 09-14 is NOT "one task"; it is 6 separate
   tasks.

---

## Coordination Pattern

You (the coordinating agent) orchestrate like this:

```
Phase N Worker (subagent) -> Phase N Output -> Phase N Verifier (subagent) -> PASS/FAIL
                                                                 |
                                              +------------------+------------------+
                                              | PASS                                | FAIL
                                              v                                     v
                                   Phase N+1 Worker                Phase N Remediation Worker
                                                                     |
                                                                     v
                                                          Phase N Verifier -> PASS/FAIL
                                                          (repeat remediation until PASS or blocked)
```

---

## Example: Executing a 16-Phase Plan

### WRONG WAY

```
Phase 03 -> 04 -> 05 -> 06 -> 09 -> 11 -> 16
           (Skipped 07, 08, 10, 12, 13, 14, 15!)
```

### RIGHT WAY

```
Phase 03 (stub)       -> Verify 03
Phase 04 (tests)      -> Verify 04
Phase 05 (impl)       -> Verify 05
Phase 06 (config stub)-> Verify 06
Phase 07 (config tests)-> Verify 07
Phase 08 (config impl) -> Verify 08
Phase 09 (stream stub) -> Verify 09
Phase 10 (stream tests)-> Verify 10
Phase 11 (stream impl) -> Verify 11
Phase 12 (tool stub)   -> Verify 12
Phase 13 (tool tests)  -> Verify 13
Phase 14 (tool impl)   -> Verify 14
Phase 15 (integration) -> Verify 15
Phase 16 (e2e tests)   -> Verify 16
```

---

## Task Tracking for Plans

When starting a multi-phase plan, create tasks/todos for EVERY phase up front,
including verification phases (P03, P03a, P04, P04a, ...). Each task must
identify the role of the subagent that will execute it.

Example task list:

| Task ID | Description | Role |
|---------|-------------|------|
| P03     | Phase 03: Create stub | implementation agent |
| P03a    | Phase 03a: Verify stub | review agent |
| P04     | Phase 04: Write tests | implementation agent |
| P04a    | Phase 04a: Verify tests | review agent |
| P05     | Phase 05: Implement | implementation agent |
| P05a    | Phase 05a: Verify implementation | review agent |
| ...     | EVERY SINGLE PHASE MUST BE LISTED | |

---

## Subagent Launch Template

For EACH phase, launch a worker subagent, wait for completion, then launch a
verifier subagent. Only proceed to the next phase when verification passes.

### Phase N Worker

```
Task:
  Description: Phase N - <short description>

  Prompt:
    CONTEXT: You are implementing Phase N of <total> phases.

    PREREQUISITE CHECK:
    Verify Phase N-1 was completed by checking for <specific artifacts>.
    If Phase N-1 artifacts are missing, return "ERROR: Phase N-1 not complete".

    YOUR TASK:
    <Specific instructions for Phase N>

    DELIVERABLES:
    <Specific files/changes for Phase N>

    DO NOT:
    - Skip ahead to Phase N+1
    - Combine with other phases
    - Implement anything beyond Phase N scope

  Role: <implementation role for your language>
```

### Phase N Verifier

```
Task:
  Description: Verify Phase N

  Prompt:
    Verify Phase N implementation is complete.

    CHECK:
    <Specific verification criteria for Phase N>

    RETURN:
    - PASS if all criteria met
    - FAIL with specific issues if not

  Role: <review role for your language>
```

ONLY if PASS, proceed to Phase N+1.

---

## Phase Skipping Detection

Before starting any phase after 03, ALWAYS check:

```
Current Phase: N
Last Completed: LAST

If N != LAST + 1:
    ERROR - Cannot skip from Phase LAST to Phase N
    STOP and complete the missing phases first.
```

---

## Common Mistakes to Avoid

### 1. "Efficient" Batching

WRONG: "Let me do Phase 09-14 in one subagent since they are all tool
integration."
RIGHT: Launch 6 separate subagents for phases 09, 10, 11, 12, 13, 14.

### 2. Skipping "Obvious" Phases

WRONG: "Phase 07 is just tests, I will skip to Phase 08 implementation."
RIGHT: Do Phase 07 (tests fail), then Phase 08 (make tests pass).

### 3. Jumping to "Important" Phases

WRONG: "Phase 16 is integration tests, that is important, let me jump there."
RIGHT: Complete phases 03-15 first, as they build the foundation for 16.

### 4. Merging Verify Steps

WRONG: "I will verify phases 03-06 together at the end."
RIGHT: Verify each phase immediately before proceeding to the next.

---

## Phase Dependencies

Many phases depend on previous phases:

- Phase 08 (config impl) NEEDS Phase 07 (config tests) to know what to implement.
- Phase 11 (stream impl) NEEDS Phase 10 (stream tests) to verify correctness.
- Phase 16 (integration) NEEDS Phases 03-15 to have something to integrate.

---

## Verification Must Be Atomic

Each verification is pass/fail for THAT PHASE ONLY:

WRONG: "Phases 03-06 look good overall."
RIGHT:
```
Phase 03: PASS - Stub structure correct
Phase 04: PASS - 25 behavioral tests created
Phase 05: FAIL - 3 tests not passing
Phase 06: BLOCKED - Cannot proceed until Phase 05 passes
```

---

## When to Stop

If any phase fails verification:

1. Do NOT proceed to the next phase.
2. Send the failed phase back to an appropriate subagent for remediation.
3. Re-run the phase verification with the reviewer subagent.
4. Repeat the remediation -> verification loop until PASS or blocked.
5. Never skip ahead hoping to "come back later."

---

## Summary Checklist

- [ ] I created tasks for EVERY phase upfront, including verification phases.
- [ ] Each task identifies the role of the executing subagent.
- [ ] I am executing phases in numerical order.
- [ ] Each phase gets one worker + one verifier subagent.
- [ ] I wait for verification PASS before proceeding.
- [ ] I never skip numbers (03 -> 04 -> 05, not 03 -> 05).
- [ ] I never batch phases (09-14 is 6 phases, not 1).
- [ ] I check for previous phase completion before starting.
- [ ] If verification fails, I remediate with a subagent and re-verify until PASS.

Remember: The plan author numbered the phases for a reason. Respect the sequence.
