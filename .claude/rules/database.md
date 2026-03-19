# Database: Drizzle ORM + Cloudflare D1

Rules for schema design, migrations, and querying. Apply whenever modifying the database schema, writing queries, or running migrations.

## Schema Changes

- All schema changes require a migration file — never alter a table in production without one
- Workflow for schema changes:
  1. Edit the schema in `src/lib/server/db/schema.ts`
  2. Run `npm run db:generate` to create the migration file
  3. Run `npm run db:migrate` to apply locally
  4. Commit both the schema change and the migration file together
- Never manually edit generated migration files — regenerate them instead

## Production Migrations

- Apply migrations to production D1 before deploying code that depends on them:
  ```bash
  wrangler d1 migrations apply <db-name> --remote
  ```
- The CI/CD deploy workflow applies migrations automatically — don't skip this step when deploying manually

## Query Patterns

- Use Drizzle's query builder for all queries — avoid raw SQL strings except for complex operations that Drizzle can't express
- Use `db.query.*` (relational API) for queries with relations — it's more readable than joins
- Always type query results — use `typeof schema.tableName.$inferSelect` for row types
- Avoid `SELECT *` — specify columns explicitly in production queries

## Local vs. Production

- Local dev uses `better-sqlite3` via `DATABASE_URL` in `.env`
- Production uses the D1 binding from `platform.env.DB`
- Keep a DB abstraction layer in `src/lib/server/db/index.ts` that handles both — don't scatter the `platform.env.DB` reference throughout the codebase

## Naming Conventions

- Table names: snake_case, plural (e.g., `users`, `session_tokens`)
- Column names: snake_case (e.g., `created_at`, `user_id`)
- Foreign key columns: `<table_singular>_id` (e.g., `user_id` references `users.id`)
