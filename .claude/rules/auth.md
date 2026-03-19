# Authentication Patterns

Rules for session-based authentication. Apply when implementing login/logout, protecting routes, or handling user identity.

## Session Storage

- Session tokens live in HTTP-only cookies only — never `localStorage`, `sessionStorage`, or JS-accessible cookies
- Set cookies with `HttpOnly`, `Secure`, and `SameSite=Lax` at minimum
- Generate session tokens with the Web Crypto API — not `Math.random()` or predictable IDs:
  ```ts
  const token = crypto.randomUUID();
  ```

## Password Handling

- Always hash passwords with `bcryptjs` using at least 10 rounds before storing
- Never log, return, or store plaintext passwords at any point
- On login, use `bcrypt.compare()` — never compare hashes with `===`
- On password reset, invalidate all existing sessions for the user

## Route Protection

- Validate sessions in `hooks.server.ts` and attach the user to `event.locals` — don't repeat auth logic per-route
- In `+page.server.ts` load functions, read from `locals.user` — don't re-query the DB for the session
- Redirect unauthenticated users with `redirect(303, '/login')` — don't return 401 for page routes
- Protected API routes (`+server.ts`) should return `error(401)` for missing/invalid sessions

## CSRF

- SvelteKit form actions have built-in CSRF protection via the `Origin` header check — don't disable it
- For custom `fetch`-based mutations, include the session cookie and validate `Origin` server-side

## Session Lifecycle

- Invalidate the session record in the DB on logout — don't rely on cookie expiry alone
- Rotate session tokens after privilege escalation (e.g., password change, email verification)
- Set a reasonable expiry (e.g., 30 days for remember-me, 24 hours for standard sessions)
