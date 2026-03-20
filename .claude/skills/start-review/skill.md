---
name: start-review
description: Initialize a repo review session — clones the target repo, verifies/installs tools, captures reviewer state, and launches the analysis menu.
argument-hint: "<git-url>"
---

# Start Review

## Overview

This skill initializes a repo review session from scratch. Work through each step in order. Do not skip steps or combine them. Always stop and wait for user input at designated pause points.

---

## Step 0 — Welcome

Greet the Dev Eng with a short, natural welcome (3–4 sentences). Explain that this skill will clone the target repo into `workspace/`, verify the required analysis tools are installed (trivy, gitleaks, cloc), and then present a scan menu so they can choose the scope of the review. Let them know you'll ask a few quick questions before anything runs.

**STOP. Wait for the user to respond before proceeding.**

---

## Step 1 — Collect Reviewer Info

Ask two questions in a single message:

1. What is your name? (Used in the report metadata and local state file.)
2. What is the purpose of this review? (Optional — e.g. "security audit for Q1 release", "routine dependency check".)

Store both answers. You will write them to `CLAUDE.local.md` in Step 6.

**STOP. Wait for the user to provide their name and purpose before continuing.**

---

## Step 2 — Get Git URL

If `$ARGUMENTS` was provided when the skill was invoked, use it as the git URL and skip asking.

Otherwise, ask: "What is the Git URL of the repo you want to review?"

Validate the input looks like a git URL — it should start with `https://` or `git@`. If it doesn't match, tell the user and ask again.

---

## Step 3 — OS Detection

Run the following command to detect the operating system:

```bash
uname -s 2>/dev/null || echo "Windows"
```

Classify the result:
- `Darwin` → macOS
- `Linux` → Linux
- `Windows` (or anything else) → Windows

Store the OS for use in Step 4.

---

## Step 4 — Detect & Install Tools

Check whether each of the three required tools is installed using `command -v <tool>`.

**Tools to check:** `trivy`, `gitleaks`, `cloc`

For any tool that is missing, auto-install it using the appropriate command for the detected OS:

| Tool | macOS | Windows | Linux |
|------|-------|---------|-------|
| trivy | `brew install aquasecurity/trivy/trivy` | `winget install Aqua.Trivy` | See below |
| gitleaks | `brew install gitleaks` | `winget install Zricethezav.Gitleaks` | `apt-get install gitleaks` |
| cloc | `brew install cloc` | `winget install AlDanial.Cloc` | `apt-get install cloc` |

**Linux trivy install:**
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

After all installs complete, re-verify each tool with a version check and capture its path:

**macOS / Linux:**
```bash
trivy --version && command -v trivy
gitleaks version && command -v gitleaks
cloc --version && command -v cloc
```

**Windows (run via PowerShell):**
```powershell
trivy --version; (Get-Command trivy).Source
gitleaks version; (Get-Command gitleaks).Source
cloc --version; (Get-Command cloc).Source
```

Store the version string and full path for each tool — you will write both to `CLAUDE.local.md` in Step 6.

Display a checklist showing the result, for example:
```
✓ trivy 0.50.0  →  /usr/local/bin/trivy
✓ gitleaks 8.18.0  →  /usr/local/bin/gitleaks
✓ cloc 1.98  →  /usr/local/bin/cloc
```

If any tool fails to install or verify, report the error and ask the user how to proceed before continuing.

---

## Step 5 — Clone Repo

Derive the repo name from the Git URL:
- Take the last path segment of the URL
- Strip a trailing `.git` suffix if present
- Example: `https://github.com/acme/my-app.git` → `my-app`

Check if `workspace/<repo-name>/` already exists. If it does, warn the user:
> "A directory at `workspace/<repo-name>/` already exists. This is a fresh review — it will be overwritten."

Then clone (or re-clone) the repo:
```bash
git clone <url> workspace/<repo-name>
```

If the directory already existed, delete it first:
```bash
rm -rf workspace/<repo-name>
git clone <url> workspace/<repo-name>
```

Confirm the clone succeeded by running:
```bash
git -C workspace/<repo-name> log --oneline -1
```

If the clone fails, report the error and stop — do not proceed to Step 6.

---

## Step 6 — Write CLAUDE.local.md

Write the following state file to `CLAUDE.local.md` in the f-cat-new root directory. Substitute all `<placeholders>` with real values collected in earlier steps. Use the current timestamp for `Started` and `Cloned At`.

```markdown
# Active Review

**Reviewer:** <name>
**Review Purpose:** <notes or "Not specified">
**Started:** <YYYY-MM-DD HH:MM>

## Target Repo
- **URL:** <git-url>
- **Local Path:** workspace/<repo-name>/
- **Cloned At:** <timestamp>

## Tools Available
- trivy: <version> (<path>)
- gitleaks: <version> (<path>)
- cloc: <version> (<path>)

## Review History
| Date | Repo | Scope | Report |
|------|------|-------|--------|
| (none yet) | | | |

## Notes
<reviewer notes, or "None">
```

Confirm the file was written successfully.

---

## Step 7 — Scan Menu

Present the following options to the Dev Eng using AskUserQuestion:

> **What type of scan would you like to run?**
>
> 1. **Full scan** — Run trivy (vulnerabilities), gitleaks (secrets), and cloc (code stats) on the entire repo
> 2. **Security only** — Run trivy + gitleaks only
> 3. **Code stats only** — Run cloc for language breakdown and line counts
> 4. **Custom scope** — Specify a subdirectory or choose which tools to run

Wait for their selection.

Once the user selects an option, acknowledge it briefly (one sentence), then **immediately proceed to run the scan** — do not ask them to run a separate command:

- **Full scan (1):** Proceed with Step 7a — Full Scan.
- **Security only (2):** Proceed with Step 7b — Security Scan.
- **Code stats only (3):** Proceed with Step 7c — Code Stats.
- **Custom scope (4):** Ask them to describe the subdirectory or specific tools they want, then proceed with Step 7d — Custom Scan.

---

## Step 7a — Full Scan

Run all three tools against `workspace/<repo-name>/`. Run them sequentially and display results as each completes.

**Trivy — vulnerability scan:**
```bash
trivy fs workspace/<repo-name>/ --format table --exit-code 0
```

**Gitleaks — secrets scan:**
```bash
gitleaks detect --source workspace/<repo-name>/ --no-git
```

**Cloc — code stats:**
```bash
cloc workspace/<repo-name>/
```

After all three complete, display a summary section:
```
## Scan Summary
- Trivy: <X critical, Y high, Z medium vulnerabilities>
- Gitleaks: <X secrets found / No secrets detected>
- Cloc: <top 3 languages and total lines>
```

Then proceed to Step 8.

---

## Step 7b — Security Scan

Run trivy and gitleaks only against `workspace/<repo-name>/`.

**Trivy — vulnerability scan:**
```bash
trivy fs workspace/<repo-name>/ --format table --exit-code 0
```

**Gitleaks — secrets scan:**
```bash
gitleaks detect --source workspace/<repo-name>/ --no-git
```

Display a summary:
```
## Scan Summary
- Trivy: <X critical, Y high, Z medium vulnerabilities>
- Gitleaks: <X secrets found / No secrets detected>
```

Then proceed to Step 8.

---

## Step 7c — Code Stats

Run cloc only against `workspace/<repo-name>/`.

```bash
cloc workspace/<repo-name>/
```

Display the cloc output in full, then summarize the top 3 languages by line count.

Then proceed to Step 8.

---

## Step 7d — Custom Scan

Ask the user: "Which tools would you like to run? (trivy / gitleaks / cloc — you can choose any combination.) And is there a specific subdirectory to scan, or the full repo?"

Use the path they specify (or `workspace/<repo-name>/` if none given). Run only the tools they requested, following the same commands as above but substituting the path.

Display results for each tool run, then proceed to Step 8.

---

## Step 8 — Update Review History

Update the `## Review History` table in `CLAUDE.local.md` by appending a new row with today's date, the repo name, the scan scope chosen, and `(no report yet)` as the report column.

Example row:
```
| 2026-03-19 | signal-track | Full scan | (no report yet) |
```

Confirm the update was written, then tell the Dev Eng: "Review session complete. Run `/scan` at any time to run another scan on this repo."
