# TypeScript Development Rules

This document defines the language-specific rules for TypeScript projects using
the planning system. It pairs with the shared methodology in
[\_base/PLAN.md](../_base/PLAN.md) and execution rules in
[\_base/COORDINATING.md](../_base/COORDINATING.md).

## CORE PRINCIPLE: TEST-DRIVEN DEVELOPMENT IS MANDATORY

Every line of production code must be written in response to a failing test.
No exceptions.

## Quick Reference

### Must Do

- Write test first (RED), minimal code to pass (GREEN), refactor if valuable
- Test behavior, not implementation
- Use TypeScript strict mode (no `any`, no type assertions)
- Work with immutable data only
- Achieve 100% behavior coverage of the public API
- Follow the existing project conventions for verification

### Never Do

- Write production code without a failing test
- Test implementation details
- Add narrative comments that restate code
- Mutate data structures
- Create speculative abstractions

## Technology Stack

- **Language**: TypeScript (strict mode required)
- **Testing**: the project's test framework (e.g. Vitest, Jest)
- **Validation**: schema-first validation (e.g. Zod)
- **State**: immutable patterns only

## TDD Process

### Red-Green-Refactor (follow strictly)

1. **RED**: write a failing test for the next small behavior
2. **GREEN**: write ONLY enough code to make the test pass
3. **REFACTOR**: assess if refactoring adds value. If yes, improve. If no, move
   on.
4. **COMMIT**: feature + tests together, refactoring separately

### Example TDD Flow

```typescript
// 1. RED - Test first
describe('calculateTotal', () => {
  it('should sum item prices', () => {
    expect(calculateTotal([{ price: 10 }, { price: 20 }])).toBe(30);
  });
});

// 2. GREEN - Minimal implementation
const calculateTotal = (items: Item[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

// 3. REFACTOR - Only if it improves clarity (this is already clean, so skip)
// 4. COMMIT - "feat: add calculateTotal function"
```

## TypeScript Rules

### Required Compiler Options

```json
{
  "strict": true,
  "noImplicitAny": true,
  "strictNullChecks": true,
  "noImplicitThis": true,
  "noUnusedLocals": true,
  "noUnusedParameters": true,
  "noImplicitReturns": true,
  "noFallthroughCasesInSwitch": true
}
```

### Type Guidelines

- Schema-first validation; derive types from schemas
- No `any` - use `unknown` with type guards
- No type assertions - use type predicates
- Explicit return types on all functions

## Testing Guidelines

### Test Structure

- **Describe**: feature/component name
- **It**: specific behavior in plain English
- **Arrange-Act-Assert**: clear test sections
- **Single assertion**: one behavior per test

### What to Test

- Public API behavior
- Input to output transformations
- Edge cases and error conditions
- Integration between units
- Schema validation

### What NOT to Test

- Implementation details
- Private methods
- Third-party libraries
- Mock interactions (mock theater)

## Code Patterns

### Immutability

```typescript
// BAD: Mutation
function addItem(cart: Cart, item: Item) {
  cart.items.push(item); // Mutates!
  return cart;
}

// GOOD: Immutable
function addItem(cart: Cart, item: Item): Cart {
  return { ...cart, items: [...cart.items, item] };
}
```

### Error Handling

```typescript
// BAD: Throwing exceptions for control flow
try {
  const user = getUser(id);
} catch (e) {
  // Handle missing user
}

// GOOD: Explicit error states
const result = getUser(id);
if (result.error) {
  // Handle error case
} else {
  // Use result.data
}
```

### Function Design

- Pure functions preferred
- Single responsibility
- Explicit dependencies
- No side effects in business logic

## Project Organization

### File Structure

```
src/
  features/
    auth/
      auth.schema.ts      # validation schemas
      auth.service.ts     # business logic
      auth.service.spec.ts # tests
      auth.types.ts       # derived types
```

### Naming Conventions

- **Files**: kebab-case.ts
- **Classes/Types**: PascalCase
- **Functions/Variables**: camelCase
- **Constants**: UPPER_SNAKE_CASE
- **Test files**: *.spec.ts (or *.test.ts, matching the project convention)

## Anti-Patterns to Avoid

### 1. Premature Abstraction

```typescript
// BAD: Creating abstractions before they are needed
interface Repository<T> {
  find(id: string): T;
  save(item: T): void;
  // ... 20 more methods
}

// GOOD: Start concrete, extract when pattern emerges
class UserService {
  getUser(id: string): User {
    /* ... */
  }
}
```

### 2. Test-After Development

```typescript
// BAD: Writing tests after implementation
function complexBusinessLogic() {
  // 200 lines of untested code
}
// "I will add tests later" (never happens)

// GOOD: TDD ensures testable design
it('should calculate discount for premium users', () => {
  expect(calculateDiscount(premiumUser, 100)).toBe(90);
});
// Then implement calculateDiscount
```

### 3. Over-Engineering

```typescript
// BAD: Complex patterns for simple problems
class UserFactoryBuilderStrategy {
  /* ... */
}

// GOOD: Simple solutions first
function createUser(data: UserData): User {
  return { ...data, id: generateId() };
}
```

## Performance Considerations

### Only Optimize When

1. Performance issue is measured and proven
2. It is a critical path
3. The optimization does not harm readability

### Performance Rules

- Profile before optimizing
- Optimize algorithms, not micro-optimizations
- Document why optimization was necessary

## Security Guidelines

### Input Validation

- Validate ALL external inputs with schema validation
- Sanitize user-generated content
- Use parameterized queries
- Never trust client data

### Authentication/Authorization

- Use established libraries (do not roll your own)
- Implement proper session management
- Follow OWASP guidelines

## Review Checklist

Before submitting code, verify:

- [ ] All tests pass
- [ ] 100% behavior coverage of public API
- [ ] No TypeScript errors
- [ ] No linting warnings
- [ ] No console output or debug code
- [ ] All TODOs addressed
- [ ] Code is self-documenting
- [ ] Follows immutability patterns
- [ ] Error cases handled explicitly

## Common Mistakes and How to Fix Them

### Mistake 1: Testing Implementation

```typescript
// BAD
it('should call database.find', () => {
  const mockDb = { find: jest.fn() };
  service.getUser('123');
  expect(mockDb.find).toHaveBeenCalledWith('123');
});

// GOOD
it('should return user data for valid ID', () => {
  const user = service.getUser('123');
  expect(user).toEqual({ id: '123', name: 'Alice' });
});
```

### Mistake 2: Implicit Dependencies

```typescript
// BAD
function processOrder() {
  const config = globalConfig; // Hidden dependency
  const db = DatabaseConnection.getInstance(); // Hidden dependency
}

// GOOD
function processOrder(config: Config, db: Database) {
  // Explicit dependencies
}
```

### Mistake 3: Mixed Concerns

```typescript
// BAD
function saveUser(userData: UserData) {
  // Validation mixed with persistence
  if (!userData.email.includes('@')) throw new Error();
  database.save(userData);
  emailService.sendWelcome(userData.email); // Side effect
}

// GOOD
const validateUser = (data: unknown): User => UserSchema.parse(data);
const saveUser = (user: User): void => database.save(user);
const notifyUser = (email: Email): void => emailService.sendWelcome(email);
```

## Remember

- **TDD is not optional** - it is the foundation of quality
- **Simplicity beats cleverness** every time
- **Working software** over perfect architecture
- **Fast feedback** over comprehensive planning
- **Refactoring** is an investment decision, not a requirement
