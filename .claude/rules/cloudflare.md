# Cloudflare Edge Runtime

Rules for working within Cloudflare Pages / Workers constraints. Apply whenever writing server-side code, environment config, or deployment-related changes.

## Runtime Constraints

- No Node.js built-ins: `fs`, `path`, `child_process`, `crypto` are unavailable at the edge
  - Use the Web Crypto API (`crypto.subtle`) instead of Node's `crypto`
  - Use `URL` and `URLSearchParams` instead of Node's `url`
- Check any npm package for Workers compatibility before installing — many Node-only packages will silently fail at deploy time
- `wrangler pages dev` simulates the Cloudflare runtime locally — use it when testing D1 or KV bindings, not plain `vite dev`

## Environment Variables

- In server routes and load functions, access env vars from `platform.env`, not `process.env`
  ```ts
  // Correct
  export const load = ({ platform }) => {
    const db = platform.env.DB;
  };
  // Wrong
  const secret = process.env.SESSION_SECRET;
  ```
- `process.env` works only during the Vite build step — never rely on it at runtime
- Store secrets in Cloudflare dashboard under **Settings → Environment Variables**, not in `wrangler.toml`

## Database

- `better-sqlite3` is for local development only — it cannot run in the Workers runtime
- In production, always use `platform.env.DB` (the D1 binding defined in `wrangler.toml`)
- Abstract the DB access behind a helper that swaps implementations based on environment to avoid duplicating this logic everywhere

## Deployment

- Never push directly to the `cloudflare` branch to trigger deploys
- Do not connect the GitHub repo in the Cloudflare dashboard — this creates a duplicate build pipeline
- D1 migrations must be applied separately: `wrangler d1 migrations apply <db-name> --remote`
- `CLOUDFLARE_API_TOKEN` requires Pages **Edit** + D1 **Edit** permissions — read-only tokens will fail silently on migration apply
