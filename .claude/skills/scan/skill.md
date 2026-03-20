---
name: scan
description: Run security and code analysis tools (trivy, gitleaks, cloc) against the active review repo. Use after /start-review, or standalone for re-scans.
argument-hint: "[--security | --stats | --custom]"
---

# Scan

## Overview

This skill runs analysis tools against the repo that is currently under review. It reads the active review state from `CLAUDE.local.md` to determine the repo path, then runs the requested tools and displays the results.

Work through the steps in order. Do not skip steps.

---

## Step 1 — Load Review State

Read `CLAUDE.local.md` from the f-cat-new root directory.

Extract:
- **Repo path:** the value of `Local Path` (e.g. `workspace/signal-track/`)
- **Repo name:** derived from the path (e.g. `signal-track`)

If `CLAUDE.local.md` does not exist or does not contain a `## Target Repo` section, stop and tell the user:
> "No active review session found. Run `/start-review <git-url>` to initialize one first."

---

## Step 2 — Determine Scan Mode

Check `$ARGUMENTS`:

| Argument | Mode |
|----------|------|
| *(none)* | Full scan — trivy + gitleaks + cloc |
| `--security` | Security only — trivy + gitleaks |
| `--stats` | Code stats only — cloc |
| `--custom` | Custom — ask the user which tools and path |

If the argument is unrecognized, tell the user the valid options and stop.

---

## Step 3 — Confirm and Run

Tell the user which scan mode is running and which path will be scanned (one line), then immediately begin.

### Full scan

Run all three tools sequentially. Display output as each completes.

**Trivy — vulnerability scan:**
```bash
trivy fs <repo-path> --format table --exit-code 0
```

**Gitleaks — secrets scan:**
```bash
gitleaks detect --source <repo-path> --no-git
```

**Cloc — code stats:**
```bash
cloc <repo-path>
```

### Security only (`--security`)

**Trivy:**
```bash
trivy fs <repo-path> --format table --exit-code 0
```

**Gitleaks:**
```bash
gitleaks detect --source <repo-path> --no-git
```

### Code stats (`--stats`)

```bash
cloc <repo-path>
```

### Custom (`--custom`)

Ask the user: "Which tools would you like to run? (trivy / gitleaks / cloc — any combination.) Is there a specific subdirectory to scan, or the full repo?"

Use the path they provide (default: the repo root from `CLAUDE.local.md`). Run only the tools they requested using the same commands above, substituting their path.

---

## Step 4 — Display Summary

After all tools have run, display a `## Scan Summary` section:

- **Full scan:**
  ```
  ## Scan Summary
  - Trivy: <X critical, Y high, Z medium vulnerabilities — or "No vulnerabilities found">
  - Gitleaks: <X secrets detected — or "No secrets detected">
  - Cloc: <top 3 languages with line counts, total lines>
  ```

- **Security only:** omit Cloc line.
- **Code stats only:** omit Trivy and Gitleaks lines.
- **Custom:** include only the tools that were run.

---

## Step 5 — Update Review History

Append a row to the `## Review History` table in `CLAUDE.local.md`:

```
| <YYYY-MM-DD> | <repo-name> | <scan mode> | (no report yet) |
```

Confirm the update was written.
