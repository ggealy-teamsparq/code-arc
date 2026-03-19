# Styling: Tailwind CSS 4 + shadcn-svelte

Rules for UI styling and component usage. Apply when building or modifying any UI.

## Component Library

- Use shadcn-svelte components from `$lib/components/ui/` for all common UI primitives — don't rebuild buttons, dialogs, inputs, etc. from scratch
- Add new shadcn components with: `npx shadcn-svelte@latest add <component>`
- Customize components by editing the files in `$lib/components/ui/` directly — shadcn components are owned by the project, not a dependency
- Build compound components in `$lib/components/` using shadcn primitives as building blocks

## Tailwind 4

- Tailwind 4 uses CSS-native configuration — there is no `tailwind.config.js`
- Add custom design tokens (colors, spacing, fonts) as CSS custom properties in `app.css`:
  ```css
  @theme {
    --color-brand: #your-color;
    --font-display: 'Your Font', sans-serif;
  }
  ```
- Use `@layer` for custom utility classes — don't add them directly to component `<style>` blocks

## Class Merging

- Always use the `cn()` utility for conditional or merged class strings:
  ```ts
  import { cn } from '$lib/utils';
  // Correct
  class={cn('base-class', isActive && 'active-class', className)}
  // Wrong
  class={`base-class ${isActive ? 'active-class' : ''}`}
  ```
- Use `tailwind-variants` for components with multiple variants — avoid long ternary class strings

## Colors & Dark Mode

- Use CSS variables defined by shadcn (`--background`, `--foreground`, `--primary`, etc.) — don't hardcode hex values in components
- Dark mode is handled by `mode-watcher` — use the `dark:` variant in Tailwind classes, not JS-toggled class names
- Never use `bg-white` or `text-black` directly — use semantic tokens like `bg-background` and `text-foreground`

## Icons

- Use `lucide-svelte` for all icons — import individually to keep bundle size small:
  ```ts
  import { ChevronRight } from 'lucide-svelte';
  ```
- Set a consistent default size via a wrapper component if icons are used extensively
