# Plan Template for Multi-Phase Features

Use this template together with [PLAN.md](./PLAN.md) (methodology) and
[COORDINATING.md](./COORDINATING.md) (execution rules). Language-specific rules
live in the matching `RULES.md` for your language.

## Plan Header

```markdown
# Plan: [FEATURE NAME]

Plan ID: PLAN-YYYYMMDD-[FEATURE]
Generated: YYYY-MM-DD
Total Phases: [N]
Requirements: [List of REQ-IDs this plan implements]

## Critical Reminders

Before implementing ANY phase, ensure you have:

1. Completed preflight verification (Phase 0.5)
2. Defined integration contracts for multi-component features
3. Written integration tests BEFORE unit tests
4. Verified all dependencies and types exist as assumed
```

## Phase Template

Each phase MUST follow this structure:

````markdown
# Phase [NN]: [Phase Title]

## Phase ID

`PLAN-YYYYMMDD-[FEATURE].P[NN]`

## Prerequisites

- Required: Phase [NN-1] completed
- Verification: `grep -r "@plan:PLAN-YYYYMMDD-[FEATURE].P[NN-1]" .`
- Expected files from previous phase: [list]
- Preflight verification: Phase 0.5 MUST be completed before any implementation phase

## Requirements Implemented (Expanded)

For EACH requirement this phase implements, provide:

### REQ-XXX: [Requirement Title]

**Full Text**: [Copy the complete requirement text here - DO NOT just reference]
**Behavior**:

- GIVEN: [precondition]
- WHEN: [action]
- THEN: [expected outcome]
**Why This Matters**: [1-2 sentences explaining the user value]

## Implementation Tasks

### Files to Create

- `path/to/file` - [description]
  - MUST include: `@plan:PLAN-YYYYMMDD-[FEATURE].P[NN]`
  - MUST include: `@requirement:REQ-XXX`

### Files to Modify

- `path/to/existing/file`
  - [change description]
  - ADD comment: `@plan:PLAN-YYYYMMDD-[FEATURE].P[NN]`
  - Implements: `@requirement:REQ-XXX`

### Required Code Markers

Every function/class/test created in this phase MUST include a header comment:

    /**
     * @plan PLAN-YYYYMMDD-[FEATURE].P[NN]
     * @requirement REQ-XXX
     * @pseudocode lines X-Y (if applicable)
     */
````

## Verification Commands

### Automated Checks (Structural)

```bash
# Check plan markers exist
grep -r "@plan:PLAN-YYYYMMDD-[FEATURE].P[NN]" . | wc -l
# Expected: [N] occurrences

# Check requirements covered
grep -r "@requirement:REQ-XXX" . | wc -l
# Expected: [N] occurrences

# Run phase-specific tests (use your project's test runner)
<test-command> --filter "@plan:.*P[NN]"
# Expected: All pass
```

### Structural Verification Checklist

- [ ] Previous phase markers present
- [ ] No skipped phases (P[NN-1] exists)
- [ ] All listed files created/modified
- [ ] Plan markers added to all changes
- [ ] Tests pass for this phase
- [ ] No "TODO" or "NotImplemented" in phase code

### Deferred Implementation Detection (MANDATORY after impl phases)

Run ALL of these checks. If ANY match, the phase FAILS.

```bash
# Check for TODO/FIXME/HACK markers left in implementation
grep -rn -E "(TODO|FIXME|HACK|STUB|XXX|WIP)" [modified-files] | grep -v test
# Expected: No matches (or only in comments explaining WHY, not WHAT to do)

# Check for "cop-out" comments
grep -rn -E "(in a real|in production|ideally|for now|placeholder|not yet|will be)" [modified-files] | grep -v test
# Expected: No matches

# Check for empty/trivial implementations
grep -rn -E "return \[\]|return \{\}|return None|return null" [modified-files] | grep -v test
# Expected: No matches in implementation code (stubs are OK in stub phases only)
```

### Semantic Verification Checklist (MANDATORY)

Go beyond markers. Actually verify the behavior exists.

#### Behavioral Verification Questions (answer ALL before proceeding)

1. **Does the code DO what the requirement says?**
   - [ ] I read the requirement text
   - [ ] I read the implementation code (not just checked the file exists)
   - [ ] I can explain HOW the requirement is fulfilled

2. **Is this REAL implementation, not placeholder?**
   - [ ] Deferred implementation detection passed (no TODO/HACK/STUB)
   - [ ] No empty returns in implementation
   - [ ] No "will be implemented" comments

3. **Would the test FAIL if the implementation were removed?**
   - [ ] Test verifies actual outputs, not just that code ran
   - [ ] Test would catch a broken implementation

4. **Is the feature REACHABLE by users?**
   - [ ] Code is called from existing code paths
   - [ ] There is a path from the entry point (UI/CLI/API) to this code

5. **What is MISSING?** (list gaps that need fixing before proceeding)
   - [ ] [gap 1]
   - [ ] [gap 2]

#### Feature Actually Works

```bash
# Manual test command (RUN THIS and paste actual output):
[insert feature-specific test command]
# Expected behavior: [describe what should happen]
# Actual behavior: [paste what actually happens]
```

#### Integration Points Verified

- [ ] Caller passes correct data type to callee (verified by reading both files)
- [ ] Callee processes data correctly (verified by tracing execution)
- [ ] Return value used correctly by caller (verified at usage site)
- [ ] Error handling works at component boundaries (verified by inducing error)

#### Lifecycle Verified

- [ ] Components initialize in documented order
- [ ] Async operations are awaited (no fire-and-forget)
- [ ] Resources are cleaned up on failure/success
- [ ] No race conditions in concurrent scenarios

#### Edge Cases Verified

- [ ] Empty/null input handled
- [ ] Invalid input rejected with a clear error
- [ ] Boundary values work correctly
- [ ] Resource limits respected

## Success Criteria

- All verification commands return expected results
- No phases skipped in sequence
- Plan markers traceable in codebase

## Failure Recovery

If this phase fails:

1. Rollback commands: [specific version-control commands]
2. Files to revert: [list]
3. Cannot proceed to Phase [NN+1] until fixed

## Phase Completion Marker

Create: `project-plans/[feature]/.completed/P[NN].md`

```markdown
Phase: P[NN]
Completed: YYYY-MM-DD HH:MM
Files Created: [list with line counts]
Files Modified: [list with diff stats]
Tests Added: [count]
Verification: [paste of verification command outputs]
```

---

## Example Phase (Filled Out)

```markdown
# Phase 07: Configuration Integration TDD

## Phase ID
`PLAN-20250113-CONFIG.P07`

## Prerequisites
- Required: Phase 06 completed
- Verification: `grep -r "@plan:PLAN-20250113-CONFIG.P06" .`
- Expected files from previous phase:
  - `src/config/ConfigurationManager` (stub)
  - corresponding test file
- Preflight verification: Phase 0.5 completed

## Requirements Implemented (Expanded)

### REQ-003.1: Configuration Mode Setting
**Full Text**: Users MUST be able to configure a setting via the CLI with modes: off, strip, replace
**Behavior**:
- GIVEN: User is in an active session
- WHEN: User executes `set mode strip`
- THEN: All subsequent outputs have the relevant content stripped
**Why This Matters**: Some environments cannot handle the content correctly, causing failures

## Implementation Tasks

### Files to Create
- test file for the configuration command
  - MUST include: `@plan:PLAN-20250113-CONFIG.P07`
  - MUST include: `@requirement:REQ-003.1`
  - Test: `set mode [value]` command
  - Test: `unset` command
  - Test: Invalid mode rejection
  - Test: Completion suggestions

### Files to Modify
- existing config test file
  - Add test suite for configuration setting
  - ADD comment: `@plan:PLAN-20250113-CONFIG.P07`
  - Implements: `@requirement:REQ-003.4` (hierarchy testing)

## Verification Commands

### Automated Checks
```bash
# Check plan markers exist
grep -r "@plan:PLAN-20250113-CONFIG.P07" . | wc -l
# Expected: 8+ occurrences

# Run phase-specific tests
<test-command> --filter "@plan:.*P07"
# Expected: Tests exist but fail naturally until P08
```

### Manual Verification Checklist
- [ ] Phase 06 markers present (ConfigurationManager)
- [ ] Test file created for the configuration command
- [ ] Tests follow behavioral pattern (no mocks)
- [ ] Tests will fail naturally until implementation
- [ ] All tests tagged with plan and requirement IDs

## Success Criteria
- 8+ tests created for configuration functionality
- All tests tagged with P07 marker
- Tests fail with "not implemented" not "cannot find"

## Failure Recovery
1. Revert test directories to the previous commit
2. Re-run Phase 07 with corrected requirements

## Phase Completion Marker
Create: `project-plans/config/.completed/P07.md`
```

---

## Preflight Verification Phase Template (Phase 0.5)

Before implementation begins, create this mandatory phase:

```markdown
# Phase 0.5: Preflight Verification

## Purpose
Verify ALL assumptions before writing any code.

## Dependency Verification
| Dependency | Version Check Output | Status |
|------------|----------------------|--------|
| [dep1]     | [paste output]       | OK/MISSING |

## Type/Interface Verification
| Type Name | Expected Definition | Actual Definition | Match? |
|-----------|---------------------|-------------------|--------|
| [Type1]   | [what plan assumes] | [what code shows] | YES/NO |

## Call Path Verification
| Function | Expected Caller | Actual Caller | Evidence |
|----------|-----------------|---------------|----------|
| [func1]  | [where plan says] | [grep output] | [file:line] |

## Test Infrastructure Verification
| Component | Test File Exists? | Test Patterns Work? |
|-----------|-------------------|---------------------|
| [comp1]   | YES/NO            | YES/NO              |

## Blocking Issues Found
[List any issues that MUST be resolved before proceeding]

## Verification Gate
- [ ] All dependencies verified
- [ ] All types match expectations
- [ ] All call paths are possible
- [ ] Test infrastructure ready

IF ANY CHECKBOX IS UNCHECKED: STOP and update the plan before proceeding.
```

---

## Inline Requirement Expansion Template

When referencing requirements, ALWAYS expand them inline. This forces planners
to UNDERSTAND the requirement, not just reference it.

```markdown
### Scenario: Profile Parsing

**Requirement ID**: REQ-PROF-001.1
**Requirement Text**: The CLI MUST recognize the --profile flag followed by a value
**Behavior Specification**:
- GIVEN: User runs `myapp --profile '{"provider":"example"}'`
- WHEN: CLI parses arguments
- THEN: the parsed profile equals the provided value

**Why This Matters**: Without this, automation cannot pass inline configuration

**Test Case** (language-agnostic):

    it parses the --profile value argument:
        result = parseBootstrapArgs(["--profile", '{"provider":"example"}'])
        assert result.profileJson == '{"provider":"example"}'
```

---

## Plan Execution Tracking

At the start of the plan, create an execution tracker. Update it after EACH phase.

```markdown
# project-plans/[feature]/execution-tracker.md

## Execution Status

| Phase | ID   | Status | Started | Completed | Verified | Semantic? | Notes |
|-------|------|--------|---------|-----------|----------|-----------|-------|
| 0.5   | P0.5 | [ ]    | -       | -         | -        | N/A       | Preflight verification |
| 03    | P03  | [ ]    | -       | -         | -        | [ ]       | Create stub |
| 04    | P04  | [ ]    | -       | -         | -        | [ ]       | Write TDD tests |
| 05    | P05  | [ ]    | -       | -         | -        | [ ]       | Implementation |
| 06    | P06  | [ ]    | -       | -         | -        | [ ]       | Config stub |
| 07    | P07  | [ ]    | -       | -         | -        | [ ]       | Config TDD |
| 08    | P08  | [ ]    | -       | -         | -        | [ ]       | Config impl |
| ...   | ...  | ...    | ...     | ...       | ...      | ...       | ... |
| Last  | P##  | [ ]    | -       | -         | -        | [ ]       | Integration / E2E |

Note: "Semantic?" tracks whether semantic verification (feature actually works)
was performed, not just structural verification (files exist).

## Completion Markers
- [ ] All phases have @plan markers in code
- [ ] All requirements have @requirement markers
- [ ] Verification script passes
- [ ] No phases skipped
```
