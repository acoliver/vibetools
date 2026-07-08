# Rust Development Rules

This document defines the language-specific rules for Rust projects using the
planning system. It pairs with the shared methodology in
[\_base/PLAN.md](../_base/PLAN.md) and execution rules in
[\_base/COORDINATING.md](../_base/COORDINATING.md).

It is intentionally opinionated.

---

## Core Principles

### 1. TDD is the default

Every production change should begin from a failing test for the next small
behavior.

Use the normal loop:
1. **RED**: write the failing test
2. **GREEN**: write the smallest real implementation that passes
3. **REFACTOR**: improve only if it clearly helps

If a test cannot be written first because the harness is genuinely missing, the
task is not "skip testing." The task is:
- create the missing harness, or
- explicitly document the gap and close it as part of the work.

### 2. Behavioral evidence beats structural evidence

Value tests that prove:
- a user-visible outcome
- a semantic contract
- a persistence guarantee
- an integration contract
- an externally meaningful state transition

Structural tests are sometimes useful, but they are weak evidence and do not
substitute for behavioral coverage.

### 3. Do not test your own mocks

Mocks, fakes, and stubs are allowed as boundary controls. They are **not** the
thing to prove.

If the assertion only proves that a value the test injected can still be read
back, the test is bad.

### 4. Do not overfit tests to implementation details

Refactors that preserve behavior should not break strong tests. If a test fails
because the call graph changed but the behavior stayed correct, the test was
probably asserting the wrong thing.

### 5. Honest coverage only

Do not hide low coverage with exclusions, fake-green tests, or mock theater. Do
not lower thresholds or broaden ignore rules without explicit approval.

Do not re-exclude hard-to-test code just to improve numbers. Do not claim
quality is improved unless the tests provide real behavioral confidence.

### 6. No hollow implementations

Implementation code must do real work. The following are failures in real
implementation phases unless explicitly allowed by the task:
- `todo!()`
- `unimplemented!()`
- placeholder strings
- empty implementations returning defaults with no behavior
- "temporary" branches that silently swallow required logic

### 7. Integrate with the real system

Do not build isolated "correct-looking" code that never becomes reachable. New
code must connect to real callers, real flows, and real state transitions.

### 8. Follow the project's actual conventions

Use the existing stack and conventions already present in the target project.
Do not invent parallel systems when an established one already exists.

---

## Quick Reference

### Must Do

- Write the next failing behavioral test first
- Prefer public-boundary and observable-outcome tests
- Use realistic inputs and outputs
- Keep dependencies explicit
- Use existing Cargo workflows for verification
- Keep coverage honest
- Add integration coverage for real call paths

### Never Do

- Write production code without a failing test unless the task is explicitly
  harness-building
- Test values that the test itself injected and nothing more
- Assert internal call chains as your main evidence of correctness
- Count mock theater as strong coverage
- Hide coverage problems with exclusions or weaker gates
- Introduce `ServiceV2`, duplicate modules, or speculative parallel
  implementations
- Leave placeholder or hollow logic in production code
- Block the main/UI thread with work that belongs off-thread

---

## Language and Tooling

- **Language**: Rust (edition 2021+)
- **Formatting**: `cargo fmt --all`
- **Linting**: `cargo clippy` (treat warnings as errors where the project does)
- **Testing**: `#[test]` for normal Rust tests; project-specific test harnesses
  where applicable
- **Primary verification**: run the project's standard quality command (e.g.
  `cargo test`, `cargo clippy`, or a project-defined `cargo qa` alias)

## Error Handling

- Prefer `Result` and explicit error propagation over panic-driven control flow
- Use typed errors where the domain matters
- Use `anyhow` only where looser application-boundary error aggregation is
  already the project convention
- Panic only for true programmer errors or impossible states, not ordinary
  invalid input or expected runtime failures

## State and Mutability

- Prefer simple, explicit state transitions
- Avoid hidden global coupling unless the project architecture already requires
  it
- Prefer clear ownership and data flow over interior mutability tricks
- Mutation is acceptable when it is the natural Rust design, but it must remain
  explicit, understandable, and behaviorally covered

## Design

- Prefer concrete code over speculative abstractions
- Add traits, wrappers, and generic layers only when they serve an actual current
  need
- Keep business logic out of UI/plumbing where possible
- Make system boundaries explicit: UI, presenter, services, storage, external
  clients

---

## Test Quality Rules

### The Three Categories

#### 1. Behavioral Tests (preferred)

A behavioral test proves something meaningful outside the code's internal
structure.

Examples:
- save data, reload it, and verify persistence
- invalid input returns the documented error
- stale response is ignored and current state is preserved
- an action causes the user-visible state to change correctly
- a request built for an external boundary has the correct contract

These are the tests that should carry most of the confidence.

#### 2. Structural Tests (allowed but weak)

A structural test mainly proves shape, construction, routing, or state
projection.

Examples:
- builder/setter methods store fields correctly
- enum variants are constructible
- routing function maps command X to target Y
- default state starts empty

These are not worthless, but they should not be mistaken for strong behavior
coverage.

#### 3. Mock Theater (usually bad)

A mock-theater test mainly proves the test harness or mocked plumbing, not the
product behavior.

Examples:
- asserting a mock was called without proving the user-visible effect
- asserting internal steps in a call chain instead of the resulting behavior
- forwarding fake values through fake layers and then asserting the same fake
  values arrived

These tests may occasionally help while building a seam, but they are weak
evidence and should not dominate the suite.

---

## Bad Test Patterns

### 1. Mock tautology / self-fulfilling test

```rust
let mut thing = MockThing::default();
thing.value = "some string".to_string();
assert_eq!(thing.value, "some string");
```

This is bad because the test creates the fact it later "proves." It tests the
mock setup, not behavior.

### 2. Interaction-only test

```rust
sut.do_work();
assert!(dependency.was_called());
```

Usually weak or bad because it proves implementation structure rather than
outcome. This is only strong when the interaction itself is the contract at a
real boundary, such as:
- writing to storage
- publishing an event
- sending a request to an external API
- enqueueing a job

Even then, prefer asserting meaningful payload/contract details rather than just
call counts.

### 3. Wiring-chain theater

```rust
button.click();
assert!(presenter.was_called());
assert!(backend.was_called());
assert_eq!(label.text(), "mocked value we invented");
```

This is better than a pure tautology, but still weak if the main evidence is only
that mocked layers forwarded mocked values. It becomes stronger when the test
asserts real behavior such as:
- loading state appears
- stale results are ignored
- persistence changed
- error state is shown correctly
- visible state matches a realistic returned contract

---

## What Good Tests Look Like

Prefer tests like these:

- **Persistence**: save data, reload it, and verify durable state
- **Error contracts**: missing or invalid config yields the expected error and
  leaves prior valid state intact
- **Service behavior**: the public input produces the right state transition or
  output, not just internal calls
- **Regression tests**: prove a previously broken user-facing behavior now works
  and stays working

Good tests should answer:
- What behavior matters?
- What public action happened?
- What observable result proves it worked?

---

## Test Review Heuristics

Before keeping or adding a test, ask:

1. **Did the test create the fact it later asserts?** If yes, it is probably weak
   or bad.
2. **Would the test fail if a real bug were introduced?** If no, it is not
   earning its keep.
3. **Would the test survive a safe refactor that preserves behavior?** If no, it
   is probably overfit to implementation.
4. **Does the test prove something a user, API consumer, or real boundary would
   notice?** If no, it is probably structural at best.
5. **Are mocks acting as inputs, or are they the whole thing being "proven"?**
   They should be inputs, not evidence.
6. **Is this the strongest test we can reasonably write for this behavior?** If
   no, write the stronger one.

---

## Using Mocks and Fakes Correctly

Allowed:
- fake storage directories
- fake API responses used as boundary inputs
- fake clocks or deterministic test harnesses
- test doubles for expensive or nondeterministic external systems

Preferred pattern:

```rust
fake_backend.respond_with(success_payload());
button.click();
assert_eq!(screen.status_text(), "Ready");
assert_eq!(screen.result_text(), "Processed 3 items");
```

Avoid:

```rust
button.click();
assert!(presenter.was_called());
assert!(backend.was_called());
assert_eq!(mock_backend.last_payload(), expected_payload);
```

The second pattern mostly proves internal choreography. The first proves
behavior.

---

## Production Code Rules

### Keep code reachable and real

- New logic must be exercised by a real caller or a clear integration path
- Do not land dead abstractions waiting for future wiring
- Do not create parallel "new" modules instead of modifying the existing flow

### Keep code simple

- Prefer the smallest design that satisfies the current requirement
- Extract abstractions only after a pattern is proven
- Do not introduce framework-like layers for single-use logic

### Keep boundaries explicit

- UI code should focus on view concerns
- presenter/coordinator code should focus on coordination and behavior
- services should own business logic and external-system interaction
- storage layers should own persistence details

### Avoid control-flow panics

Bad:
```rust
fn get_user(id: &str) -> User {
    panic!("user missing")
}
```

Better:
```rust
fn get_user(id: &str) -> Result<User, UserError> {
    // explicit failure path
}
```

### No placeholder implementations in real phases

Bad:
```rust
fn send_message(&self, _text: &str) -> String {
    "placeholder".to_string()
}
```

Bad (if the requirement is to load the real profile):
```rust
fn load_profile(&self) -> Result<Profile, Error> {
    Ok(Profile::default())
}
```

---

## Verification Rules

### Default local verification

Before claiming a Rust implementation task is complete, run the appropriate
local checks. For most code changes this means at least:

```bash
cargo test
cargo clippy
```

Or the project's combined quality command if one is defined (e.g. `cargo qa`).
For coverage work, also run the project's coverage command (e.g.
`cargo coverage` or `cargo tarpaulin`).

### Coverage rules

- Coverage must remain honest
- Do not "improve coverage" by excluding the hard-to-test code you were supposed
  to test
- Do not use structural or mock-theater tests as a substitute for missing
  behavioral coverage
- If coverage is below the gate, report the real number and the real gap

### When call assertions are acceptable

Use interaction assertions only when the interaction itself is the behavior
contract, such as:
- event publication
- persistence write
- external request dispatch
- job scheduling

Even then, assert the contract, payload, or semantic outcome, not just "called
once."

---

## Review Checklist

Before considering a change complete, verify:

- [ ] A failing test existed first, or the task explicitly built the missing
      harness
- [ ] New tests primarily prove behavior, not structure
- [ ] The test does not only verify mocks or values injected by the test itself
- [ ] Interaction assertions are justified by a real boundary contract
- [ ] No placeholder or hollow implementation remains
- [ ] No duplicate or speculative parallel implementation was introduced
- [ ] `cargo test` and `cargo clippy` pass
- [ ] Coverage was run when the task required honest coverage verification
- [ ] Any remaining risk or uncovered behavior is called out explicitly

---

## One-Sentence Standard

A bad test proves the test's own setup or the current implementation wiring.
A good test proves a behavior or contract that matters outside the code under
test.

That is the standard to optimize for.
