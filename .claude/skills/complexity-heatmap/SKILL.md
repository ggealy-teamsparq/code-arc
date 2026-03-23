---
name: complexity-heatmap
description: Locate cyclomatic complexity hotspots where logic is too dense to safely refactor. Use when evaluating code maintainability, planning refactors, or prioritizing test coverage.
argument-hint: "<path-or-git-url> [--summary | --deep]"
---

# Complexity Heatmap

## Overview

This skill analyzes source code to produce a complexity heatmap identifying cyclomatic hotspots — functions and files where logic density makes safe refactoring difficult. It uses Lizard for accurate per-function cyclomatic complexity when available, with a heuristic fallback for unsupported languages or when Lizard is not installed.

When a `code-provenance` report exists for the same target, the skill cross-references complexity with age, churn, and bus factor data to surface the most actionable danger zones.

Work through the steps in order. Do not skip steps.

---

## Step 1 — Resolve Target

Check `$ARGUMENTS` for a target and mode flag.

**Target resolution (check in this order):**

1. **Git URL** — If the argument looks like a git URL (starts with `https://`, `git@`, or ends with `.git`), check if `workspace/<repo-name>` already exists. If it does, tell the user the existing clone is being reused. If not, clone the repo:
   ```bash
   git clone <url> workspace/<repo-name>
   ```
   Use the repo name derived from the URL (e.g., `https://github.com/org/my-app.git` → `my-app`). Set the target path to `workspace/<repo-name>`.

2. **Local path** — If the argument is a local path, verify it exists. If it does not, tell the user and stop.

3. **No argument** — If no path is provided, check if `CLAUDE.local.md` exists in the code-arc root. If it does, extract the `Local Path` from the `## Target Repo` section and use that as the target.

4. **Fallback** — If none of the above apply, default to the current working directory.

**Mode:**

| Flag | Mode | Description |
|------|------|-------------|
| *(none)* | Standard | Per-function complexity with file-level heatmap |
| `--summary` | Summary | File-level aggregates only — fast, no per-function detail |
| `--deep` | Deep | Full report with heuristic fallback analysis and provenance cross-reference |

Store the resolved **target path** and **mode** for use in subsequent steps.

---

## Step 2 — Detect and Install Lizard

Check whether Lizard is installed:

```bash
lizard --version 2>/dev/null
```

If Lizard is not found, install it:

```bash
pip install lizard
```

If `pip` is not available, try `pip3`:

```bash
pip3 install lizard
```

After install, verify:

```bash
lizard --version
```

If installation fails (e.g., no Python/pip available), warn the user:
> "Lizard could not be installed (Python/pip not found). Falling back to heuristic-only analysis. Results will be approximate."

Store whether Lizard is available as a flag for subsequent steps.

---

## Step 3 — Detect Languages and Build File Inventory

Identify the languages present in the target path:

```bash
find <target-path> -type f \( -name "*.cs" -o -name "*.java" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.rb" -o -name "*.php" -o -name "*.swift" -o -name "*.rs" -o -name "*.svelte" \) | head -500
```

Exclude common vendor/generated directories:
- `node_modules/`, `vendor/`, `packages/`, `bin/`, `obj/`, `.git/`, `dist/`, `build/`, `__pycache__/`

Count files per language extension. Store the inventory.

**Lizard-supported languages:** C, C++, C#, Java, JavaScript, TypeScript, Python, Go, Ruby, PHP, Swift, Rust, Objective-C, Scala, Kotlin, Lua

For files in unsupported languages (or if Lizard is unavailable), mark them for heuristic analysis in Step 5.

For targets with more than 200 source files, inform the user of the total count and focus on the top 100 largest files by line count. Mention the cutoff in the output.

---

## Step 4 — Lizard Analysis

Skip this step if Lizard is not available.

Run Lizard against the target path:

```bash
lizard <target-path> --sort cyclomatic_complexity --length 0 --CCN 0 -Eduplicate
```

This outputs every function with:
- **CCN** — cyclomatic complexity number
- **NLOC** — lines of code (non-comment, non-blank)
- **Token count**
- **Parameter count**
- **Function name and location** (file:line)

Parse the output and store per-function records:
- File path
- Function name
- Start line
- CCN
- NLOC
- Parameter count

**Complexity thresholds:**

| CCN | Level | Meaning |
|-----|-------|---------|
| 1–5 | Simple | Easy to understand and test |
| 6–10 | Moderate | Manageable but worth monitoring |
| 11–20 | Complex | Difficult to test, consider splitting |
| 21–50 | Very Complex | High risk, should be refactored |
| 51+ | Untestable | Nearly impossible to fully test — urgent refactor candidate |

Also compute per-file aggregates:
- **Max CCN** — highest function CCN in the file
- **Avg CCN** — average across all functions in the file
- **Total functions**
- **Hotspot count** — number of functions with CCN > 10

---

## Step 5 — Heuristic Analysis

Run this step for:
- All files if Lizard is not available
- Files in languages Lizard doesn't support
- All files in `--deep` mode (to supplement Lizard data)

For each file in the inventory, analyze the raw source code.

### 5a — Branch Keyword Density

Count occurrences of branching/looping keywords per file:

```bash
grep -cE '\b(if|else|elif|elsif|switch|case|for|foreach|while|do|try|catch|except|finally|&&|\|\||\?)\b' <file>
```

Compute **branch density** = keyword count / total lines of code.

| Density | Level |
|---------|-------|
| < 0.05 | Low |
| 0.05–0.10 | Moderate |
| 0.10–0.20 | High |
| > 0.20 | Very High |

### 5b — Nesting Depth

Estimate maximum nesting depth by analyzing indentation:

```bash
awk '{ match($0, /^[[:space:]]*/); depth = RLENGTH; if (depth > max) max = depth } END { print max }' <file>
```

For tab-indented files, multiply tab count by 4 to normalize. Convert raw indentation to approximate nesting level by dividing by the file's base indent unit (2, 4, or tab).

| Max Nesting | Level |
|-------------|-------|
| 1–3 | Simple |
| 4–5 | Moderate |
| 6–7 | Deep |
| 8+ | Extreme |

### 5c — Function Length

Estimate function boundaries using language-appropriate patterns:

| Language | Function pattern |
|----------|-----------------|
| C#, Java, JS/TS, Go | `\b(function\|def\|func\|void\|int\|string\|bool\|async)\b.*\{` or method signatures |
| Python | `^\s*def\s+` |
| Ruby | `^\s*def\s+` |

Count lines between function boundaries.

| Length | Level |
|--------|-------|
| 1–20 | Short |
| 21–50 | Medium |
| 51–100 | Long |
| 101+ | Very Long |

### 5d — Heuristic Complexity Score

Compute a composite score (0–100) per file:

| Factor | Weight | Score Logic |
|--------|--------|-------------|
| Branch density | 35% | Map density level to 0–100 |
| Max nesting depth | 30% | Map nesting level to 0–100 |
| Longest function | 25% | Map function length level to 0–100 |
| File size (LOC) | 10% | Higher score for files > 300 LOC |

---

## Step 6 — Provenance Cross-Reference (Deep mode only)

Skip this step unless mode is `--deep`.

Check if a provenance report exists for the same target:
- Look for the most recent `*-provenance.md` file in the reports directory
- Or check if `code-provenance` data can be gathered quickly

If provenance data is available, cross-reference each file's complexity data with:
- **Age** — file birth date
- **Bus factor** — number of authors
- **Churn** — commit count
- **Fix ratio** — percentage of fix commits

Compute a **danger score** (0–100) that combines complexity and provenance:

| Factor | Weight |
|--------|--------|
| Complexity (CCN or heuristic score) | 50% |
| Age (from provenance) | 15% |
| Bus factor (from provenance) | 15% |
| Fix ratio (from provenance) | 20% |

**Danger classification:**

| Score | Level | Meaning |
|-------|-------|---------|
| 0–25 | Low | Healthy — complexity is manageable |
| 26–50 | Moderate | Monitor — complexity is notable but context is acceptable |
| 51–75 | Elevated | Priority review — complex code with concerning provenance |
| 76–100 | Critical | Urgent — complex, old, single-author, bug-prone code |

---

## Step 7 — Display Report

Present the report in the following format. Adapt sections based on mode and tool availability.

### Header

```
## Complexity Heatmap Report

**Target:** <path>
**Mode:** <Standard | Summary | Deep>
**Analysis:** <Lizard | Heuristic | Hybrid>
**Files analyzed:** <N>
**Date:** <YYYY-MM-DD>
```

If Lizard was used, note the version. If heuristic fallback was used, note that results are approximate.

### Summary Section (all modes)

```
### Overview

| Metric | Value |
|--------|-------|
| Total files analyzed | <N> |
| Total functions found | <N> (Lizard) or N/A (heuristic) |
| Most complex file | <filename> (max CCN: <N> or heuristic: <N>) |
| Most complex function | <name> in <file> (CCN: <N>) — Lizard only |
| Hotspot files (CCN > 10) | <N> |
| Average file complexity | <N> |
```

### Complexity Distribution (all modes)

```
### Complexity Distribution

| Level | Files | % | Functions (if Lizard) |
|-------|-------|---|----------------------|
| Simple (CCN 1–5) | <N> | <N>% | <N> |
| Moderate (CCN 6–10) | <N> | <N>% | <N> |
| Complex (CCN 11–20) | <N> | <N>% | <N> |
| Very Complex (CCN 21–50) | <N> | <N>% | <N> |
| Untestable (CCN 51+) | <N> | <N>% | <N> |
```

### File Heatmap Table (all modes)

Show one row per file, sorted by max complexity descending:

```
### File Heatmap

| File | LOC | Functions | Max CCN | Avg CCN | Hotspots | Heuristic | Level |
|------|-----|-----------|---------|---------|----------|-----------|-------|
| <path> | <N> | <N> | <N> | <N> | <N> | <N>/100 | <level> |
```

Limit to top 30 files. If more were analyzed, note the cutoff.

For `--summary` mode, omit the Functions, Max CCN, and Avg CCN columns (use heuristic score only).

### Function Hotspot Table (Standard and Deep modes, Lizard only)

List all functions with CCN > 10, sorted by CCN descending:

```
### Function Hotspots

| Function | File | Line | CCN | NLOC | Params | Level |
|----------|------|------|-----|------|--------|-------|
| <name> | <file> | <N> | <N> | <N> | <N> | <level> |
```

Limit to top 30 functions. If more qualify, note the cutoff.

### Heuristic Breakdown (Standard and Deep modes, when heuristic is used)

For the top 10 most complex files by heuristic score, show the factor breakdown:

```
### Heuristic Detail — <filename>

| Factor | Value | Score |
|--------|-------|-------|
| Branch density | <N> keywords / <N> LOC = <N> | <N>/100 |
| Max nesting | <N> levels | <N>/100 |
| Longest function | <N> lines | <N>/100 |
| File size | <N> LOC | <N>/100 |
| **Weighted total** | | **<N>/100** |
```

### Danger Zones (Deep mode only)

Cross-referenced complexity + provenance findings:

```
### Danger Zones — Complexity x Provenance

| File | Complexity | Age | Bus Factor | Fix % | Danger Score | Level |
|------|-----------|-----|------------|-------|--------------|-------|
| <path> | <N> | <age> | <N> | <N>% | <N> | <level> |
```

Sort by danger score descending. Limit to files scoring >= 51 or top 20, whichever is more.

### Hotspot Findings (all modes)

List files with max CCN > 10 or heuristic score > 50, with a one-line explanation:

```
### Hotspot Findings

- **<filename>** (max CCN: <N>) — <primary driver, e.g., "3 functions over CCN 20, deepest nesting 8 levels">
- ...
```

If no files qualify, display: "No significant complexity hotspots identified."

### Recommendations (all modes)

Based on the findings, provide 3–5 actionable recommendations. Tailor these to the actual results — do not use generic advice. Examples:

- "**<filename>:<function>** (CCN: 47) — Extract the nested switch-case into a lookup table or strategy pattern"
- "**<filename>** has 12 functions over CCN 15 — consider splitting into smaller modules by responsibility"
- "**<filename>** scores Critical in the danger zone (complex + legacy + single author) — prioritize adding test coverage before any modifications"

---

## Step 8 — Write Report File

Determine the report output location:

- If `CLAUDE.local.md` exists and has a `Local Path`, write to:
  ```
  workspace/<repo-name>/reports/<YYYY-MM-DD>-complexity.md
  ```
- Otherwise, write to:
  ```
  reports/<YYYY-MM-DD>-complexity.md
  ```

Create the `reports/` directory if it doesn't exist.

Write the full report content (everything displayed in Step 7) to the file.

Confirm the report was written and display the file path.

---

## Step 9 — Update Review History (if applicable)

If `CLAUDE.local.md` exists, append a row to the `## Review History` table:

```
| <YYYY-MM-DD> | <repo-name> | Complexity Heatmap (<mode>) | <report-file-path> |
```

If `CLAUDE.local.md` does not exist, skip this step.
