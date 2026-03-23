---
name: code-provenance
description: Analyze the age, authorship, churn, and risk profile of code through Git metadata. Use when evaluating code health, planning refactors, or triaging review effort.
argument-hint: "<path-or-git-url> [--summary | --deep]"
---

# Code Provenance

## Overview

This skill analyzes Git history to produce a multi-dimensional provenance report for a file, directory, or entire repo. It surfaces code age, author concentration, change velocity, commit classification, and a composite risk score.

Work through the steps in order. Do not skip steps.

---

## Step 1 — Resolve Target

Check `$ARGUMENTS` for a target and mode flag.

**Target resolution (check in this order):**

1. **Git URL** — If the argument looks like a git URL (starts with `https://`, `git@`, or ends with `.git`), clone the repo:
   ```bash
   git clone <url> workspace/<repo-name>
   ```
   Use the repo name derived from the URL (e.g., `https://github.com/org/my-app.git` → `my-app`). If `workspace/<repo-name>` already exists, skip cloning and tell the user the existing clone is being reused. Set the target path to `workspace/<repo-name>`.

2. **Local path** — If the argument is a local path, verify it exists. If it does not, tell the user and stop.

3. **No argument** — If no path is provided, check if `CLAUDE.local.md` exists in the code-arc root. If it does, extract the `Local Path` from the `## Target Repo` section and use that as the target.

4. **Fallback** — If none of the above apply, default to the current working directory.

**Mode:**

| Flag | Mode | Description |
|------|------|-------------|
| *(none)* | Standard | File-level age, churn, authors, and risk table |
| `--summary` | Summary | Repo-wide overview — fast, no blame analysis |
| `--deep` | Deep | Full report with line-level blame age distribution |

Store the resolved **target path** and **mode** for use in subsequent steps.

---

## Step 2 — Collect File Inventory

Build a list of tracked files within the target path.

```bash
git -C <repo-root> ls-files -- <target-path>
```

If the target is a single file, the inventory is just that file. If it is a directory, collect all files recursively.

For repos with more than 200 tracked files in the target path, inform the user of the count and focus analysis on the top 50 most-churned files (by commit count). Mention the cutoff in the output.

---

## Step 3 — Gather Git Metadata

For each file in the inventory, run the following commands. Batch where possible to minimize shell calls.

### 3a — File Birth and Last Touch

```bash
# First commit that introduced the file (birth date)
git log --diff-filter=A --format="%ai" -- <file> | tail -1

# Most recent commit touching the file
git log -1 --format="%ai" -- <file>
```

### 3b — Commit Count (Churn)

```bash
git rev-list --count HEAD -- <file>
```

### 3c — Author Distribution

```bash
git shortlog -sne --no-merges -- <file>
```

Extract:
- Total unique authors
- Top contributor and their commit percentage
- **Bus factor:** count of authors who collectively account for >= 80% of commits

### 3d — Change Velocity (last 12 months)

```bash
git log --format="%ai" --since="1 year ago" --no-merges -- <file>
```

Bucket commits by month. Classify the trend:
- **Accelerating** — commit count trending upward over the last 3 months vs. prior 3 months
- **Stable** — roughly flat (+/- 20%)
- **Decaying** — trending downward
- **Dormant** — zero commits in the last 6 months

### 3e — Commit Classification

```bash
git log --format="%s" --no-merges -- <file>
```

Classify each commit message by its prefix or intent:

| Prefix / Pattern | Category |
|-----------------|----------|
| `fix`, `bug`, `patch`, `hotfix` | Fix |
| `feat`, `add`, `implement` | Feature |
| `refactor`, `rename`, `move`, `restructure` | Refactor |
| `chore`, `ci`, `build`, `deps`, `bump` | Chore |
| `test`, `spec` | Test |
| `doc`, `readme` | Docs |
| *(no match)* | Other |

Compute the percentage breakdown per category for each file.

---

## Step 4 — Line-Level Blame Analysis (Deep mode only)

Skip this step unless mode is `--deep`.

For each file in the inventory (limit to top 20 files by churn if the list is large):

```bash
git blame --line-porcelain <file> | grep "^author-time"
```

Parse the Unix timestamps and bucket each line into age bands:

| Band | Label |
|------|-------|
| < 30 days | Fresh |
| 30–90 days | Recent |
| 90–365 days | Mature |
| > 1 year | Legacy |

Compute the percentage of lines in each band per file.

---

## Step 5 — Compute Risk Scores

For each file, compute a composite **risk score** (0–100) using the following weighted factors:

| Factor | Weight | Score Logic |
|--------|--------|-------------|
| Age | 20% | Higher score if median line age > 1 year (or file birth > 1 year in non-deep mode) |
| Bus factor | 25% | Higher score if bus factor = 1 (single author owns 80%+) |
| Velocity | 15% | Higher score if dormant or decaying |
| Fix ratio | 25% | Higher score if > 40% of commits are fixes |
| Churn | 15% | Higher score if commit count is in the top quartile (high churn + high fix ratio = fragile) |

Score each factor 0–100 individually, then compute the weighted average.

**Risk classification:**

| Score | Level | Meaning |
|-------|-------|---------|
| 0–25 | Low | Healthy, well-maintained code |
| 26–50 | Moderate | Normal — monitor during reviews |
| 51–75 | Elevated | Warrants closer review or refactoring discussion |
| 76–100 | High | High-risk — consider prioritizing for refactor or increased test coverage |

---

## Step 6 — Display Report

Present the report in the following format. Adapt sections based on mode.

### Header

```
## Code Provenance Report

**Target:** <path>
**Mode:** <Standard | Summary | Deep>
**Analyzed:** <file count> files
**Date:** <YYYY-MM-DD>
```

### Summary Section (all modes)

```
### Overview

| Metric | Value |
|--------|-------|
| Total files analyzed | <N> |
| Oldest file | <filename> (<age>) |
| Newest file | <filename> (<age>) |
| Most churned | <filename> (<N> commits) |
| Highest risk | <filename> (score: <N>) |
| Average bus factor | <N> |
```

### Age Distribution (all modes)

Show a table bucketing all files by age band:

```
### Age Distribution

| Band | Files | % |
|------|-------|---|
| Fresh (< 30d) | <N> | <N>% |
| Recent (30–90d) | <N> | <N>% |
| Mature (90d–1yr) | <N> | <N>% |
| Legacy (> 1yr) | <N> | <N>% |
```

For `--deep` mode, this section uses line-level blame data instead of file birth dates.

### File Detail Table (Standard and Deep modes)

Show one row per file, sorted by risk score descending:

```
### File Details

| File | Born | Last Touch | Commits | Authors | Bus Factor | Velocity | Fix % | Risk |
|------|------|------------|---------|---------|------------|----------|-------|------|
| <path> | <date> | <date> | <N> | <N> | <N> | <trend> | <N>% | <score> <level> |
```

Limit to top 30 files. If more were analyzed, note the cutoff.

### Commit Profile (Standard and Deep modes)

Show the aggregate commit classification breakdown:

```
### Commit Profile

| Category | Count | % |
|----------|-------|---|
| Fix | <N> | <N>% |
| Feature | <N> | <N>% |
| Refactor | <N> | <N>% |
| Chore | <N> | <N>% |
| Test | <N> | <N>% |
| Docs | <N> | <N>% |
| Other | <N> | <N>% |
```

### Line-Level Age Breakdown (Deep mode only)

For each of the top 10 highest-risk files, show the line-age distribution:

```
### Line-Level Age — <filename>

| Band | Lines | % | Visual |
|------|-------|---|--------|
| Fresh | <N> | <N>% | ██░░░░░░░░ |
| Recent | <N> | <N>% | ███░░░░░░░ |
| Mature | <N> | <N>% | █████░░░░░ |
| Legacy | <N> | <N>% | ████████░░ |
```

### High-Risk Findings (all modes)

List files with risk score >= 51, with a one-line explanation of the primary risk drivers:

```
### High-Risk Findings

- **<filename>** (risk: <score>) — <primary driver, e.g., "single author, 60% fix commits, dormant 8 months">
- ...
```

If no files score >= 51, display: "No high-risk files identified."

---

## Step 7 — Write Report File

Determine the report output location:

- If `CLAUDE.local.md` exists and has a `Local Path`, write to:
  ```
  workspace/<repo-name>/reports/<YYYY-MM-DD>-provenance.md
  ```
- Otherwise, write to:
  ```
  reports/<YYYY-MM-DD>-provenance.md
  ```

Create the `reports/` directory if it doesn't exist.

Write the full report content (everything displayed in Step 6) to the file.

Confirm the report was written and display the file path.

---

## Step 8 — Update Review History (if applicable)

If `CLAUDE.local.md` exists, append a row to the `## Review History` table:

```
| <YYYY-MM-DD> | <repo-name> | Code Provenance (<mode>) | <report-file-path> |
```

If `CLAUDE.local.md` does not exist, skip this step.
