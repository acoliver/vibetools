# Development Guidelines for Claude

## CORE PRINCIPLE: TEST-DRIVEN DEVELOPMENT IS MANDATORY
**Every line of production code must be written in response to a failing test. No exceptions.**

## Quick Reference (MEMORIZE THIS)

### Must Do:
- Write test first (RED) → Minimal code to pass (GREEN) → Refactor if valuable
- Test behavior, not implementation
- Use TypeScript strict mode (no `any`, no type assertions)
- Work with immutable data only
- Achieve 100% behavior coverage
- Update CLAUDE.md with learnings after each session

### Never Do:
- Write production code without a failing test
- Test implementation details
- Add comments (code must be self-documenting)
- Mutate data structures
- Create speculative abstractions

## Technology Stack
- **Language**: TypeScript (strict mode required)
- **Testing**: Vitest + React Testing Library
- **Validation**: Zod for schema-first development
- **State**: Immutable patterns only

## TDD Process

### Red-Green-Refactor (FOLLOW STRICTLY)

1. **RED**: Write a failing test for the next small behavior
2. **GREEN**: Write ONLY enough code to make the test pass
3. **REFACTOR**: Assess if refactoring adds value. If yes, improve. If no, move on.
4. **COMMIT**: Feature + tests together, refactoring separately

### Example TDD Flow
```typescript
// 1. RED - Test first
describe("calculateTotal", () => {
  it("should sum item prices", () => {
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

## TypeScript Requirements

### tsconfig.json (non-negotiable)
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### Schema-First Development
```typescript
// Define schema first
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(["user", "admin"])
});

// Derive type from schema
type User = z.infer<typeof UserSchema>;

// Use for validation at boundaries
export const parseUser = (data: unknown): User => {
  return UserSchema.parse(data);
};
```

## Testing Principles

### Test Behavior, Not Implementation
```typescript
// ✅ GOOD - Tests behavior
it("should decline payment when insufficient funds", () => {
  const result = processPayment({ amount: 100 }, { balance: 50 });
  expect(result.success).toBe(false);
  expect(result.error).toBe("Insufficient funds");
});

// ❌ BAD - Tests implementation
it("should call validateBalance", () => {
  // Never test if internal methods were called
});
```

### Test Data Factories
```typescript
const createMockUser = (overrides?: Partial<User>): User => {
  return {
    id: "123",
    email: "test@example.com",
    role: "user",
    ...overrides
  };
};
```

### CRITICAL: Use Real Schemas in Tests
```typescript
// ❌ WRONG - Never redefine schemas in tests
const TestUserSchema = z.object({ id: z.string() });

// ✅ CORRECT - Import from production code
import { UserSchema } from "@app/schemas";
```

### 100% Coverage Through Behavior
Coverage happens naturally when testing all business behaviors. Never test internals directly.

```typescript
// validator.ts (internal)
const validateAmount = (amount: number) => amount > 0 && amount <= 10000;

// processor.ts (public API) 
const processPayment = (payment: Payment) => {
  if (!validateAmount(payment.amount)) {
    return { success: false, error: "Invalid amount" };
  }
  // process...
};

// processor.test.ts - achieves 100% coverage of validator
it("rejects negative amounts", () => {
  expect(processPayment({ amount: -1 })).toEqual({ 
    success: false, 
    error: "Invalid amount" 
  });
});
```

## Code Patterns

### Use Options Objects
```typescript
// ✅ Preferred
type CreateOrderOptions = {
  items: Item[];
  customerId: string;
  shipping?: ShippingMethod;
};

const createOrder = (options: CreateOrderOptions): Order => {
  const { items, customerId, shipping = "standard" } = options;
  // ...
};

// ❌ Avoid multiple parameters
const createOrder = (items: Item[], customerId: string, shipping?: ShippingMethod): Order => {
  // ...
};
```

### Immutable Updates
```typescript
// ✅ Good
const addItem = (items: Item[], newItem: Item): Item[] => {
  return [...items, newItem];
};

// ❌ Bad
const addItem = (items: Item[], newItem: Item): Item[] => {
  items.push(newItem); // Mutation!
  return items;
};
```

### Early Returns
```typescript
// ✅ Good
const processUser = (user: User): void => {
  if (!user.isActive) return;
  if (!user.hasPermission) return;
  
  // Process user
};

// ❌ Bad
const processUser = (user: User): void => {
  if (user.isActive) {
    if (user.hasPermission) {
      // Process user
    }
  }
};
```

## Refactoring Guidelines

### When to Refactor
- After achieving green tests
- When you see knowledge duplication (not just code duplication)
- When names don't clearly express intent
- When structure could be simpler

### When NOT to Refactor
- When code is already clean and clear
- When it would create premature abstractions
- When tests would need to change (refactoring shouldn't break tests)

### DRY = Don't Repeat KNOWLEDGE (not code)
```typescript
// NOT a DRY violation - different knowledge, similar structure
const validateAge = (age: number) => age >= 18 && age <= 100;
const validateRating = (rating: number) => rating >= 1 && rating <= 5;

// IS a DRY violation - same business rule in multiple places
const FREE_SHIPPING = 50; // Use this constant everywhere
```

### Refactoring Checklist
- [ ] All tests still pass
- [ ] No changes to public APIs
- [ ] Code is more readable than before
- [ ] Commit refactoring separately

## Working with Claude

### Before Starting
1. Read existing tests to understand patterns
2. Check CLAUDE.md for project-specific knowledge
3. Identify the next behavior to implement

### During Development
1. **ALWAYS** start with a failing test
2. Stop immediately if writing code without a test
3. Keep changes small and incremental
4. Ask for clarification when requirements are ambiguous

### After Each Session
Update CLAUDE.md with:
- Patterns discovered
- Gotchas encountered
- Context that would have helped
- Project-specific conventions

## Quick Decision Guide

**Need to add a feature?**
1. Write failing test for simplest case
2. Make it pass with minimal code
3. Refactor if valuable
4. Add next test for edge case
5. Repeat

**Found a bug?**
1. Write failing test that exposes the bug
2. Fix with minimal change
3. Add more tests for related cases

**Want to refactor?**
1. Ensure all tests are green
2. Commit current state
3. Make changes without altering behavior
4. Verify all tests still pass
5. Commit refactoring separately

## Remember
- **TDD is not optional** - No production code without a failing test
- **Behavior over implementation** - Test what it does, not how
- **Small increments** - Tiny steps with frequent commits
- **CLAUDE.md is your memory** - Update it constantly

If you find yourself typing production code without a failing test, **STOP IMMEDIATELY** and write the test first.