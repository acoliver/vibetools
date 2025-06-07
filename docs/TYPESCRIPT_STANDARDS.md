# TypeScript Best Practices for LLRT

This document outlines the TypeScript standards and best practices for the LLRT project.

## Type Safety

1. **Explicit Types**: Always declare types for function parameters, return values, and variables when TypeScript cannot infer them.

   ```typescript
   // Good
   function addItem(item: ListItem): void {
     // ...
   }

   // Avoid
   function addItem(item) {
     // ...
   }
   ```

2. **Handle `unknown` Types**: Always type check and handle `unknown` types, especially in catch blocks.

   ```typescript
   try {
     // code that might throw
   } catch (error: unknown) {
     const errorMessage = error instanceof Error ? error.message : String(error);
     console.error("Error:", errorMessage);
   }
   ```

3. **Avoid Type Assertions**: Use type guards instead of type assertions (`as`) when possible.

   ```typescript
   // Good
   if (isValidResponse(response)) {
     // ...
   }

   // Avoid when possible
   const data = response as ValidResponse;
   ```

## Naming Conventions

1. **Consistent File Naming**: Use consistent casing (PascalCase) for file names that export classes.
2. **Interface Naming**: Interfaces should NOT start with `I` prefix.
3. **Type Naming**: Use PascalCase for types and interfaces.
4. **Method/Variable Naming**: Use camelCase for methods, properties, and variables.

## Code Structure

1. **Access Modifiers**: Always use access modifiers (`private`, `public`, `protected`) for class members.
2. **Return Types**: Explicitly declare return types for all functions and methods.
3. **Void Functions**: If a function doesn't return anything, explicitly declare it as `:void`.

   ```typescript
   private initialize(): void {
     // ...
   }
   ```

4. **Method Organization**: Organize class methods by visibility (public, then protected, then private) and by logical groupings.

## Error Handling

1. **Proper Error Types**: Use specific error types or create custom error classes for different error scenarios.
2. **Error Propagation**: Properly propagate and handle errors with consistent error objects.
3. **Graceful Error Recovery**: Implement graceful recovery from errors when possible.

## Debugging and Logging

1. **Descriptive Logs**: Use descriptive console messages that include context.
2. **Log Levels**: Use appropriate log levels (debug, info, warn, error).
3. **Development Logs**: Mark logs as debug that should only appear in development.

## Imports and Dependencies

1. **Import Order**: Follow a consistent import order:
   - Node.js built-in modules
   - External dependencies
   - Internal modules
   - Relative imports

2. **Path Consistency**: Use consistent path styles for imports.

3. **Use Path Aliases**: Always use path aliases instead of relative paths to improve code maintainability and readability.

   ```typescript
   // Bad - Using relative paths
   import { SomeClass } from '../../../services/SomeService';
   
   // Good - Using path aliases
   import { SomeClass } from '@services/SomeService';
   ```

4. **Path Alias Structure**: Follow the established path alias structure defined in `tsconfig.json`:

   ```typescript
   // Common aliases in this project
   import { Something } from '@services/...'; // For service modules
   import { Components } from '@ui/...';      // For UI components
   import { Types } from '@types/...';        // For type definitions
   ```

5. **No Deep Relative Paths**: Never use relative paths that go more than one level deep (i.e., avoid `../../` or deeper).

## Additional Guidelines

1. **Nullable Types**: Use optional properties (`?`) and union types with `null` or `undefined` for nullable values.
2. **Strict Mode**: Always run TypeScript in strict mode.
3. **No Any**: Avoid using `any` type whenever possible.
4. **Enums Over Constants**: Use enums for related constants.
5. **Use Interfaces for Objects**: Use interfaces for object types, especially when they represent a public API.

## Tooling

- Maintain proper TypeScript configuration in `tsconfig.json`
- Use ESLint for static code analysis
- Run type checking (`tsc --noEmit`) before committing code

These standards help maintain code quality, readability, and type safety throughout the project. 