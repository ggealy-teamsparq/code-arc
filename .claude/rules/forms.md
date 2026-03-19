# Forms: Superforms + Zod

Rules for form handling and validation. Apply when creating or modifying any form that submits data.

## Setup Pattern

All forms follow this pattern:

**Server (`+page.server.ts`):**
```ts
import { superValidate, fail } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';
import { schema } from '$lib/schemas/example';

export const load = async () => ({
  form: await superValidate(zod(schema)),
});

export const actions = {
  default: async ({ request }) => {
    const form = await superValidate(request, zod(schema));
    if (!form.valid) return fail(400, { form });

    // ... handle valid data ...

    return { form };
  },
};
```

**Component (`+page.svelte`):**
```svelte
<script lang="ts">
  import { superForm } from 'sveltekit-superforms';
  const { data } = $props();
  const { form, errors, enhance } = superForm(data.form);
</script>

<form method="POST" use:enhance>...</form>
```

## Schema Location

- Define Zod schemas in `$lib/schemas/` — one file per domain entity
- Export the inferred type alongside the schema:
  ```ts
  export const loginSchema = z.object({ ... });
  export type LoginData = z.infer<typeof loginSchema>;
  ```
- Share schemas between client and server — don't duplicate validation logic

## Validation Rules

- Server always re-validates — client-side validation is progressive enhancement only
- Use `superValidate(request, zod(schema))` on the server, never trust raw form data
- Return `fail(400, { form })` with the form object so Superforms can display field errors
- Use Formsnap's `<Field>`, `<Control>`, `<FieldErrors>` components for accessible form fields

## Error Display

- Use `$errors.fieldName` from `superForm()` for field-level errors — don't manage error state manually
- Use `$message` for form-level messages (success/error toasts via `svelte-sonner`)
- Never display raw server error messages to users — sanitize before surfacing
