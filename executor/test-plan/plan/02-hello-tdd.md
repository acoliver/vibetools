# Phase 02: Hello World TDD Tests

## Objective
Write comprehensive tests for the greet function following TDD principles.

## Deliverables
1. Create `test/hello.test.ts` with tests for:
   - Basic greeting: `greet("World")` returns `"Hello, World!"`
   - Empty name: `greet("")` returns `"Hello, Anonymous!"`
   - Whitespace name: `greet("  ")` returns `"Hello, Anonymous!"`
   - Name with spaces: `greet("John Doe")` returns `"Hello, John Doe!"`

2. Tests should use vitest or jest (check what's available)

## Success Criteria
- Tests are behavioral (test input/output, not implementation)
- All tests fail with NotYetImplemented error
- Tests cover all specified cases