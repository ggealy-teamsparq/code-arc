# Testing: Playwright + Vitest

Rules for writing and running tests. Apply when adding features, fixing bugs, or modifying existing tests.

## Test Types & Locations

| Type | Tool | Location | Purpose |
|------|------|----------|---------|
| Unit / component | Vitest | `src/**/*.test.ts` | Pure functions, utilities, isolated components |
| Integration | Vitest | `src/**/*.test.ts` | DB queries, server logic with real DB |
| E2E | Playwright | `tests/` | Full user flows through the browser |
| Accessibility | axe-core | `tests/` | Run on every new page/major component |

## E2E Tests (Playwright)

- E2E tests require a running dev server — configure `webServer` in `playwright.config.ts` rather than starting it manually
- Use page object models for repeated UI interactions — don't inline selectors across multiple test files
- Prefer `getByRole`, `getByLabel`, `getByText` over CSS selectors — tests should reflect how users interact
- Use `@faker-js/faker` for test data — no hardcoded strings like `"testuser@example.com"`
- Clean up created test data in `afterEach` / `afterAll` — tests should be independent and repeatable

## Unit Tests (Vitest)

- Co-locate unit tests with the file they test: `utils.ts` → `utils.test.ts`
- Test pure functions and utilities in isolation — mock external dependencies
- Use `describe` blocks to group related cases — one concept per `it` block

## Database in Tests

- Never mock the database in integration tests — use a real SQLite file or test D1 database
- Use a separate test database configured via `DATABASE_URL` in `.env.test`
- Run migrations on the test DB before the test suite: include in `globalSetup`

## Accessibility

- Run `axe` checks on every new page added to the app:
  ```ts
  import { checkA11y } from 'axe-playwright';
  await checkA11y(page);
  ```
- Zero `critical` or `serious` violations are required — `moderate` violations should be documented

## Running Tests

```bash
npm run test:unit          # Vitest (watch mode)
npm run test:unit -- --run # Vitest (single run, for CI)
npm run test:e2e           # Playwright
```
