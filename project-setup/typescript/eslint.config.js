/**
 * Canonical TypeScript ESLint config (flat config, ESLint 9+).
 *
 * Distilled from a mature production codebase and stripped of all monorepo
 * paths, package names, custom rules, and issue-specific enforcement blocks.
 *
 * Policy: strict — no eslint-disable directives, no loosened complexity
 * thresholds. When this config warns, CI runs with --max-warnings 0 so every
 * warning is an error in practice.
 *
 * Requires devDependencies:
 *   eslint, typescript-eslint, eslint-config-prettier, eslint-plugin-import,
 *   eslint-plugin-sonarjs, eslint-plugin-eslint-comments, globals
 *   (optional for React: eslint-plugin-react, eslint-plugin-react-hooks)
 *   (optional for Vitest: @vitest/eslint-plugin)
 */
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';
import prettierConfig from 'eslint-config-prettier';
import sonarjs from 'eslint-plugin-sonarjs';
import eslintComments from 'eslint-plugin-eslint-comments';
import globals from 'globals';

// --- Optional plugins: uncomment (and add to devDependencies) if you use them ---
// import reactPlugin from 'eslint-plugin-react';
// import reactHooks from 'eslint-plugin-react-hooks';
// import vitest from '@vitest/eslint-plugin';

/**
 * Extract rules from a plugin config that may be a flat-config array (v4+)
 * or a legacy object (v3). Returns a plain rules map.
 */
function extractRules(configs) {
  const arr = Array.isArray(configs) ? configs : [configs];
  return Object.fromEntries(arr.flatMap((c) => Object.entries(c?.rules ?? {})));
}

/** Map every rule in a config to 'warn' (preserving array-style options). */
function toWarnRules(configs) {
  return Object.fromEntries(
    Object.entries(extractRules(configs)).map(
      ([rule, config]) => [rule, Array.isArray(config) ? ['warn', ...config.slice(1)] : 'warn'],
    ),
  );
}

export default tseslint.config(
  // ── Global ignores ──────────────────────────────────────────────────────
  {
    ignores: [
      'node_modules/**',
      'dist/**',
      'build/**',
      'coverage/**',
    ],
  },

  // ── Base recommended sets ───────────────────────────────────────────────
  eslint.configs.recommended,
  ...tseslint.configs.recommended,

  // ── Main TS/TSX rules ───────────────────────────────────────────────────
  {
    files: ['**/*.{ts,tsx}'],
    plugins: {
      import: importPlugin,
      sonarjs,
      'eslint-comments': eslintComments,
    },
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        projectService: true,
        // import.meta.dirname returns undefined on Node < 20.11; fall back to cwd.
        tsconfigRootDir: import.meta.dirname ?? process.cwd(),
      },
      globals: {
        ...globals.node,
        ...globals.es2021,
      },
    },
    rules: {
      // --- Best-practice rules ---
      '@typescript-eslint/array-type': ['error', { default: 'array-simple' }],
      'arrow-body-style': ['error', 'as-needed'],
      curly: ['error', 'multi-line'],
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      '@typescript-eslint/consistent-type-assertions': ['error', { assertionStyle: 'as' }],
      '@typescript-eslint/explicit-member-accessibility': ['error', { accessibility: 'no-public' }],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-inferrable-types': ['error', { ignoreParameters: true, ignoreProperties: true }],
      '@typescript-eslint/no-namespace': ['error', { allowDeclarations: true }],
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/return-await': ['error', 'in-try-catch'],
      'import/no-relative-packages': 'error',
      'no-cond-assign': 'error',
      'no-debugger': 'error',
      'no-duplicate-case': 'error',
      'no-restricted-syntax': [
        'error',
        {
          selector: 'CallExpression[callee.name="require"]',
          message: 'Avoid using require(). Use ES6 imports instead.',
        },
        {
          selector: 'ThrowStatement > Literal:not([value=/^\\w+Error:/])',
          message: 'Do not throw string literals or non-Error objects. Throw new Error("...") instead.',
        },
      ],
      'no-unsafe-finally': 'error',
      'no-var': 'error',
      'object-shorthand': 'error',
      'one-var': ['error', 'never'],
      'prefer-arrow-callback': 'error',
      'prefer-const': ['error', { destructuring: 'all' }],
      radix: 'error',
      default-case: 'error',

      // --- Async / type safety ---
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-unnecessary-type-assertion': 'error',
      '@typescript-eslint/no-unused-expressions': ['error', { allowShortCircuit: true, allowTernary: true }],

      // --- Stricter type rules (effective errors under --max-warnings 0) ---
      '@typescript-eslint/no-misused-promises': 'warn',
      '@typescript-eslint/strict-boolean-expressions': [
        'warn',
        {
          allowString: true,
          allowNumber: false,
          allowNullableObject: true,
          allowNullableBoolean: false,
          allowNullableString: true,
          allowNullableNumber: false,
          allowAny: false,
        },
      ],
      '@typescript-eslint/consistent-type-imports': ['warn', { prefer: 'type-imports' }],
      '@typescript-eslint/switch-exhaustiveness-check': 'warn',
      '@typescript-eslint/no-unnecessary-condition': 'warn',
      '@typescript-eslint/prefer-nullish-coalescing': 'warn',
      '@typescript-eslint/prefer-optional-chain': 'warn',

      // --- Code quality ---
      'no-console': 'warn',
      'no-else-return': 'warn',
      'no-lonely-if': 'warn',
      'no-unneeded-ternary': 'warn',

      // --- Complexity limits (effective errors under --max-warnings 0) ---
      complexity: ['warn', 15],
      'max-lines': ['warn', { max: 800, skipBlankLines: true, skipComments: true }],
      'max-lines-per-function': ['warn', { max: 80, skipBlankLines: true, skipComments: true }],

      // --- SonarJS (recommended at warn, then tune specifics) ---
      ...toWarnRules(sonarjs.configs.recommended),
      'sonarjs/cognitive-complexity': ['warn', 30],
      'sonarjs/function-return-type': 'off',
      'sonarjs/no-wildcard-import': 'off',
      'sonarjs/file-header': 'off',
      // Disable rules irrelevant to non-web / non-AWS / non-DB projects.
      // Remove lines below if your project IS a web server, uses AWS CDK/CFN,
      // serves HTML, or uses a SQL database.
      'sonarjs/aws-apigateway-public-api': 'off',
      'sonarjs/aws-ec2-unencrypted-ebs-volume': 'off',
      'sonarjs/aws-iam-public-access': 'off',
      'sonarjs/aws-s3-bucket-public-access': 'off',
      'sonarjs/content-security-policy': 'off',
      'sonarjs/cookie-no-httponly': 'off',
      'sonarjs/cookies': 'off',
      'sonarjs/cors': 'off',
      'sonarjs/csrf': 'off',
      'sonarjs/disabled-auto-escaping': 'off',
      'sonarjs/insecure-cookie': 'off',
      'sonarjs/no-clear-text-protocols': 'off',
      'sonarjs/no-mixed-content': 'off',
      'sonarjs/strict-transport-security': 'off',
      'sonarjs/x-powered-by': 'off',
      'sonarjs/sql-queries': 'off',
      'sonarjs/web-sql-database': 'off',

      // --- eslint-comments (recommended at warn) ---
      ...toWarnRules(eslintComments.configs.recommended),
    },
  },

  // ── Test files: relax size limits, add Vitest rules ────────────────────
  {
    files: ['**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}', '**/__tests__/**/*.{ts,tsx}'],
    // plugins: { vitest },          // uncomment with the Vitest plugin
    rules: {
      'max-lines-per-function': 'off',
      // ...vitest.configs.recommended.rules,   // uncomment with the Vitest plugin
    },
  },

  // ── Script files: .js/.mjs/.cjs (ESLint 9 auto-detects sourceType) ──────
  // .mjs → module, .cjs → commonjs, .js → depends on package.json "type".
  {
    files: ['scripts/**/*.{js,mjs,cjs}', '*.config.{js,mjs,cjs}'],
    languageOptions: {
      globals: { ...globals.node, process: 'readonly', console: 'readonly' },
    },
    rules: {
      // Use base ESLint rule for plain JS files (the TS parser/plugins are
      // not configured for this block).
      'no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
      ],
    },
  },

  // ── React (optional): uncomment the imports above and this block ───────
  // {
  //   files: ['**/*.tsx'],
  //   ...reactPlugin.configs.flat.recommended,
  //   ...reactPlugin.configs.flat['jsx-runtime'],
  //   settings: { react: { version: 'detect' } },
  // },
  // {
  //   files: ['**/*.tsx'],
  //   plugins: { 'react-hooks': reactHooks },
  //   rules: {
  //     ...reactHooks.configs['recommended-latest'].rules,
  //     'react/jsx-no-bind': ['warn', { ignoreRefs: true, allowArrowFunctions: false, allowFunctions: false, allowBind: false }],
  //     'react/jsx-no-constructed-context-values': 'error',
  //   },
  // },

  // ── Prettier must be last ───────────────────────────────────────────────
  prettierConfig,
);
