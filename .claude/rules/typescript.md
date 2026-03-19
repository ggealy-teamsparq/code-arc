# TypeScript Conventions

Rules for type safety and TypeScript patterns. Apply to all `.ts` and `.svelte` files.

## Strictness

- Strict mode is enabled — no implicit `any`, no unchecked indexing
- Never use `any` without a comment explaining why it's unavoidable
- Prefer `unknown` over `any` for values of uncertain type — then narrow with type guards

## Imports & Path Aliases

- Use the `$lib` alias for all internal imports — no relative `../../` paths:
  ```ts
  // Correct
  import { db } from '$lib/server/db';
  // Wrong
  import { db } from '../../lib/server/db';
  ```
- Use `$lib/server/` for server-only code — SvelteKit enforces this boundary at build time

## SvelteKit Types

- Use generated types from `.svelte-kit/types/` for route-specific types:
  ```ts
  import type { PageData, ActionData } from './$types';
  ```
- Use `App.Locals` in `src/app.d.ts` to type `event.locals` (e.g., `user`, `session`)
- Use `App.PageData` for data passed through layouts if needed

## Zod as Source of Truth

- Derive TypeScript types from Zod schemas — don't define parallel interfaces:
  ```ts
  export const userSchema = z.object({ id: z.string(), email: z.string().email() });
  export type User = z.infer<typeof userSchema>;
  ```
- Use Zod for runtime validation at all system boundaries (form submissions, API responses, env vars)

## General Patterns

- Prefer `type` over `interface` for object shapes — use `interface` only when extension is needed
- Use `satisfies` operator to validate object literals against a type while preserving literal types
- Avoid type assertions (`as SomeType`) — use type guards or Zod parsing instead
- Export types from the module that owns the data — co-locate types with implementation
