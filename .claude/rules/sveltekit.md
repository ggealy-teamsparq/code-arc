# SvelteKit Patterns

Rules for working with SvelteKit in this project. Apply whenever creating or modifying routes, components, load functions, or form actions.

## Server vs. Client Boundaries

- Use `+page.server.ts` for any DB access or secret-dependent logic — never import server-only modules in `+page.ts`
- Only `+page.server.ts` and `+server.ts` files can use `platform.env` (Cloudflare bindings)
- Mark server-only modules with `$lib/server/` path — SvelteKit will error if these are imported client-side
- Use `+layout.server.ts` to load session/auth data shared across all child routes

## Data Loading

- Return data from `load` functions and consume via the `data` prop — don't call DB directly in components
- Use `PageData` / `LayoutData` types from `.svelte-kit/types/` for type-safe `data` props
- Prefer `load` functions over stores for server-fetched data
- Use `depends()` in load functions to enable `invalidate()` for reactive reloading

## Form Actions

- Prefer form actions over API routes (`+server.ts`) for any mutation triggered by a user action
- Always use `superValidate` from `sveltekit-superforms` — don't parse `request.formData()` manually
- Return `fail(400, { form })` on validation errors, never throw
- Return `{ form }` on success so Superforms can reset state

## Svelte 5 Runes

- Use `$state()`, `$derived()`, `$effect()` — not `let`/`$:` reactive declarations
- Use `$props()` for component props — not `export let`
- `$effect()` replaces `onMount` + reactive statements — avoid mixing patterns
- `$derived()` is lazy and memoized — prefer it over `$effect` for computed values

## Error Handling

- Use `error(status, message)` from `@sveltejs/kit` in load functions and actions — don't throw raw errors
- Create `+error.svelte` pages at each route level that needs custom error UI
- Use `handleError` in `hooks.server.ts` for global error logging
