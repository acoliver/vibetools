# Mocking Strategy for Jest Tests

This guide captures the mocking approach used in `ProjectIndexer.test.ts` and generalizes it for future tests. It is written for a very junior engineer or a simple LLM—just follow each step.

## 1. Align TypeScript & Jest Path Aliases

1. In `tsconfig.json` you define path aliases (e.g. `@services/*`, `@ui/*`, etc.).
2. Mirror those aliases in `jest.config.js` under `moduleNameMapper`. Example:
   ```js
   moduleNameMapper: {
     '^@services/(.*)$': '<rootDir>/src/services/$1',
     '^@ui/(.*)$': '<rootDir>/src/ui/$1',
     // ...other mappings...
   }
   ```
3. This makes `import { X } from '@services/X'` work the same in Jest and TS.

## 2. Mock Dependencies Before Importing the Unit Under Test

- Always call `jest.mock('module-path', factory)` at the top of your test file, before you import the code you are testing.
- Example for a singleton class:
  ```ts
  jest.mock('@services/diff/DiffManager', () => ({
    DiffManager: {
      getInstance: () => mockDiffManagerStub
    }
  }));
  
  // Then import the function or class under test:
  import { proposeFixHandler } from '@services/ai/functions/proposeFix';
  ```
- This override ensures that calls to `DiffManager.getInstance()` in your code return your stub.

## 3. Create Strongly‑Typed Stubs with `jest.Mocked<T>`

1. **Import the interface or class** so TypeScript knows the shape:
   ```ts
   import type { ILanguageAnalyzer } from '@services/indexing/languages/ILanguageAnalyzer';
   ```
2. **Build your stub** by casting to `jest.Mocked<YourType>`:
   ```ts
   const mockAnalyzer = {
     analyze: jest.fn().mockResolvedValue({ /* ... */ }),
     canAnalyze: jest.fn().mockReturnValue(true),
     /* other methods... */
   } as jest.Mocked<ILanguageAnalyzer>;
   ```
3. **Return it in your mock factory**:
   ```ts
   jest.mock('@services/indexing/languages/LanguageRegistry', () => ({
     LanguageRegistry: { getInstance: () => registryStub }
   }));
   ```
4. Now TypeScript and ESLint both know your stub matches the expected interface—no `any`, no `@ts-ignore`.

## 4. Use `jest.clearAllMocks()` in `beforeEach`

- Reset call counts and mock implementations before each test:
  ```ts
  describe('MyFeature', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    test('does something', () => {
      // ...
    });
  });
  ```

## 5. Respect ESLint Rules (`.eslintrc.js`)

- **No explicit `any`**: all casts for mocks should use `jest.Mocked<T>` or `as unknown as jest.Mocked<T>` if necessary.
- **No `@ts-ignore`**: instead, fix types with `jest.Mocked<T>` or correct factory signature.
- **No deep relative imports**: use your path aliases (e.g. `@services/...`, never `../../../services/...`).
- **No unused variables**: if a mock or import isn't used in tests, remove it or prefix with `_`.
- **Semi and quotes**: follow the project's style (semicolons on every statement, quotes as configured).

## Test-file exceptions

In your `.test.ts` and `.spec.ts` files, you can relax several rules to enable minimal, concise mocks:

1. **ESLint overrides** in `.eslintrc.js`:
   ```js
   module.exports = {
     // ... existing config ...
     overrides: [
       {
         files: ['**/*.test.ts', '**/*.spec.ts'],
         rules: {
           '@typescript-eslint/no-explicit-any': 'off',
           '@typescript-eslint/no-unused-vars': 'off',
           '@typescript-eslint/no-unsafe-call': 'off',
           '@typescript-eslint/no-unsafe-member-access': 'off',
           '@typescript-eslint/consistent-type-assertions': 'off'
         }
       }
     ]
   };
   ```
2. **Disable linter at the top of each test**:
   ```ts
   /* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unused-vars */
   ```
3. **Minimal stub pattern**:
   ```ts
   import type { Query, Table, Connection } from '@lancedb/lancedb';

   // Query stub
   const mockQuery = {} as unknown as Query;
   mockQuery.where = jest.fn().mockReturnThis();
   mockQuery.limit = jest.fn().mockReturnThis();

   // Table stub
   const mockTable = {} as unknown as Table;
   mockTable.search = jest.fn().mockReturnValue(mockQuery);
   mockTable.add    = jest.fn().mockResolvedValue(undefined);
   mockTable.delete = jest.fn().mockResolvedValue(undefined);

   // Connection stub
   const mockConnection = {} as unknown as Connection;
   mockConnection.openTable   = jest.fn().mockResolvedValue(mockTable);
   mockConnection.createTable = jest.fn().mockResolvedValue(mockTable);
   mockConnection.tableNames  = jest.fn().mockResolvedValue([]);

   // Override LanceDB before importing Database
   jest.mock('@lancedb/lancedb', () => ({
     __esModule: true,
     connect: jest.fn().mockResolvedValue(mockConnection)
   }));
   import { Database } from '@services/database/Database';
   ```

## 6. Example Pattern for a Singleton Service

```ts
import { describe, test, beforeEach, expect, jest } from '@jest/globals';
import type { MyService } from '@services/my/MyService';

// 1) Build a typed stub
const mockMyService = {
  doSomething: jest.fn().mockResolvedValue(true),
  getValue: jest.fn().mockReturnValue(42)
} as jest.Mocked<MyService>;

// 2) Override the module before import
jest.mock('@services/my/MyService', () => ({
  MyService: { getInstance: () => mockMyService }
}));

// 3) Import the code under test
import { myHandler } from '@services/my/myHandler';

// 4) Write tests
describe('myHandler', () => {
  beforeEach(() => jest.clearAllMocks());

  test('calls MyService', async () => {
    await myHandler();
    expect(mockMyService.doSomething).toHaveBeenCalled();
  });
});
```

## 7. Common Pitfalls and How to Avoid Them

| Pitfall                                        | Solution                                          |
|-----------------------------------------------|---------------------------------------------------|
| `Argument of type ... is not assignable to never` | Make sure `jest.mock()` returns a stub that TS can infer the type of (use `jest.Mocked<T>`). |
| `Cannot find module` with path‑alias imports  | Double‑check `moduleNameMapper` in `jest.config.js`.  |
| Explicit `any` or `@ts-ignore` everywhere     | Cast your stub to `jest.Mocked<Interface>` instead. |
| Deep relative imports                         | Always use `@alias/...` imports.                  |

---

With this pattern in place, you'll avoid the `never`/`any`/`@ts-ignore` wars and keep your tests clean, strongly‑typed, and ESLint‑compliant. Happy testing!

## 8. Build Minimal Domain Fixtures

When your code under test consumes or produces domain‑specific types (for example, `ChangeProposal`, `DiffChunk`, `FileDiff`), follow these steps:

1. **Import the interfaces and enums** from your model files:
   ```ts
   import type { ChangeProposal } from '@models/ChangeProposal';
   import { ChangeProposalStatus } from '@models/ChangeProposal';
   import type { DiffChunk, FileDiff } from '@models/FileDiff';
   import { FileDiffStatus } from '@models/FileDiff';
   ```

2. **Create minimal fixture objects** satisfying each interface:
   ```ts
   const proposalStub: ChangeProposal = {
     id: 'proposal-123',
     timestamp: Date.now(),
     title: 'Test Proposal',
     description: 'Generated by unit test',
     files: [],
     status: ChangeProposalStatus.PENDING,
     lastModified: new Date().toISOString()
   };

   const diffChunkStub: DiffChunk = {
     // DiffChunk from @models/FileDiff
     index: 0,
     originalStartLine: 1,
     originalLineCount: 1,
     modifiedStartLine: 1,
     modifiedLineCount: 1,
     type: 'modification',
     content: '// patch for chunk',
     contextBefore: '',
     contextAfter: ''
   };

   const fileDiffStub: FileDiff = {
     // FileDiff from @models/FileDiff
     id: 'diff-123',
     filePath: 'src/file.ts',
     isNewFile: false,
     originalContent: 'old content',
     modifiedContent: 'new content',
     description: '',          // required
     status: FileDiffStatus.PENDING
   };
   ```

3. **Cast your mock to `jest.Mocked<T>` using those fixtures**:
   ```ts
   const mockDiffManager: jest.Mocked<DiffManager> = {
     createProposal: jest.fn().mockResolvedValue(proposalStub),
     parseUnifiedDiff: jest.fn().mockReturnValue([diffChunkStub]),
     addFileDiff: jest.fn().mockResolvedValue(fileDiffStub),
     getProposal: jest.fn().mockReturnValue(proposalStub),
     // If your plugin listens to events:
     onDidChangeProposal: jest.fn(),
     onDidChangeFileDiff: jest.fn(),
     addChangeListener: jest.fn(),
     removeChangeListener: jest.fn()
   } as unknown as jest.Mocked<DiffManager>;
   ```

---

## 9. Example: ProposeFixPlugin Test Setup

```ts
import { describe, beforeEach, test, expect, jest } from '@jest/globals';
import type { ChangeProposal } from '@models/ChangeProposal';
import { ChangeProposalStatus } from '@models/ChangeProposal';
import type { DiffChunk, FileDiff } from '@models/FileDiff';
import { FileDiffStatus } from '@models/FileDiff';
import type { DiffManager } from '@services/diff/DiffManager';

// 1) Build fixtures
const proposalStub: ChangeProposal = { /* see step 8 */ };
const diffChunkStub: DiffChunk = { /* see step 8 */ };
const fileDiffStub: FileDiff = { /* see step 8 */ };

// 2) Mock and cast DiffManager
const mockDiffManager: jest.Mocked<DiffManager> = {
  createProposal: jest.fn().mockResolvedValue(proposalStub),
  parseUnifiedDiff: jest.fn().mockReturnValue([diffChunkStub]),
  addFileDiff: jest.fn().mockResolvedValue(fileDiffStub),
  getProposal: jest.fn().mockReturnValue(proposalStub),
  onDidChangeProposal: jest.fn(),
  onDidChangeFileDiff: jest.fn(),
  addChangeListener: jest.fn(),
  removeChangeListener: jest.fn()
} as unknown as jest.Mocked<DiffManager>;

// 3) Override the singleton before importing your plugin
jest.mock('@services/diff/DiffManager', () => ({
  DiffManager: { getInstance: () => mockDiffManager }
}));

// 4) Continue mocking other dependencies similarly...
// 5) Import and test your plugin
import { ProposeFixPlugin } from '@services/ai/plugins/ProposeFixPlugin';

describe('ProposeFixPlugin', () => {
  let plugin: ProposeFixPlugin;

  beforeEach(() => {
    jest.clearAllMocks();
    plugin = new ProposeFixPlugin();
    // stub return values using your fixtures...
  });

  test('implements interface', () => {
    expect(plugin.isEnabled()).toBe(true);
    // ... etc.
  });
});
```

With these additions you'll have an explicit, minimal pattern to follow: define complete fixtures, cast to `jest.Mocked<T>`, and wire up your mocks before importing the code under test. This prevents `never`‐type errors or missing‐property complaints. Happy testing!  