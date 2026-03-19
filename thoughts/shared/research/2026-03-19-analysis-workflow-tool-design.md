---
date: 2026-03-19T00:00:00-05:00
git_commit: (no commits yet)
branch: main
repository: ggealy-teamsparq/f-cat
topic: "Analysis Workflow Tool Design — Modeling on cc-self-train"
---

# Research: Analysis Workflow Tool Design — Modeling on cc-self-train

**Date**: 2026-03-19
**Git Commit**: (no commits yet — fresh repo)
**Branch**: main

## Research Question

How should f-cat-new be set up as an analysis workflow tool that a Dev Eng can use to review a repo, modeled on the patterns established in the cc-self-train training repo?

## Summary

The cc-self-train repo is a "learn Claude Code by doing" environment with 4 projects, 10 progressive modules, reference docs, hooks, skills, and scripts — all orchestrated through Claude Code's features (skills, hooks, subagents, MCP, tasks). The **Sentinel** project within it is the closest analogue to what f-cat-new should become: a code analyzer & test generator that scans repos, applies rules, generates reports, tracks coverage, and automates quality checks.

f-cat-new already has a strong foundation: 8 architecture rule files, 6 research agents, 8 CLI commands, 2 skills, a research-plan-implement plugin, and a SessionStart hook that checks for trivy/gitleaks/cloc. However, it has **zero application code** and a placeholder CLAUDE.md. The rules are currently SvelteKit/Cloudflare-specific, which would need to be generalized or supplemented for a multi-repo analysis tool.

## Detailed Findings

### cc-self-train: Structural Patterns Worth Adopting

#### 1. Onboarding Flow (SessionStart → /start skill)
- **Two SessionStart hooks**: welcome banner (`welcome.js`) + version checker (`check-updates.js`)
- **`/start` skill**: Interactive onboarding that detects OS, verifies toolchain, scaffolds workspace
- **`CLAUDE.local.md`**: Tracks per-user progress and preferences, survives context compaction
- **`.claude/onboarding-state.json`**: Persists onboarding state across session restarts

**Applicable to f-cat-new**: Replace the training-oriented `/start` with a `/start-review` skill that:
  - Asks which repo to analyze (path or git URL)
  - Checks for required tools (trivy, gitleaks, cloc — already in `check-software.sh`)
  - Clones or validates the target repo
  - Creates a `CLAUDE.local.md` tracking the review state

#### 2. Progressive Skill Architecture
cc-self-train defines skills that build on each other:

| Skill | Purpose |
|-------|---------|
| `/start` | Onboarding entry point |
| `/doctor` | Diagnostic check of environment |
| `/sync` | Curriculum update (maintainer tool) |
| `/recap` | Progress review |
| `/release` | Full release automation |

**Applicable to f-cat-new**: Define an analysis-focused skill set:

| Proposed Skill | Purpose | Modeled After |
|----------------|---------|---------------|
| `/start-review` | Initialize a repo review session | `/start` |
| `/scan` | Run all analysis tools on target repo | Sentinel's `/analyze` |
| `/security-scan` | Trivy + Gitleaks focused scan | Sentinel's rule engine |
| `/code-stats` | Cloc + complexity metrics | Sentinel's coverage tracking |
| `/generate-report` | Consolidate findings into report | Sentinel's `/quality-report` |
| `/doctor` | Verify tools are installed | cc-self-train's `/doctor` |

#### 3. Sentinel's Analysis Pipeline (The Core Model)

The Sentinel project builds this pipeline across 10 modules:

**Phase 1 — Scanning (Module 2)**
- Recursive file scanner: walks directories, filters by extension, skips `.git`/`node_modules`
- Rule engine: applies configurable rules to scanned files
- Starter rules: function length, missing docstrings, cyclomatic complexity

**Phase 2 — Rule Framework (Modules 3-4)**
- Rules are stateless functions returning structured `Issue` objects
- Rules stored in `rules/` directory with required schema (name, severity, description, check function)
- Path-scoped `.claude/rules/` enforce coding conventions per area

**Phase 3 — Automation (Module 5)**
- `SessionStart` hook: runs scan on startup, shows issue summary
- `PostToolUse` hook: validates rule files on write
- `Stop` hook: checks if tests were updated alongside code changes

**Phase 4 — Persistence (Module 6)**
- SQLite database via MCP server stores scan results, issues, and coverage
- `/coverage-trend` skill queries historical data

**Phase 5 — Guard Rails (Module 7)**
- `PreToolUse` hooks validate rule schemas, inject context, add metadata
- Prompt-based hooks evaluate test quality

**Phase 6 — Parallel Analysis (Module 8)**
- Three specialized subagents: `analyzer-agent`, `test-writer-agent`, `reporter-agent`
- Agent pipeline: analyzer → test-writer chain
- Fan-out across source directories

**Phase 7 — TDD & Coverage (Module 9)**
- Task dependency graphs for complex features
- Coverage parsing and historical trend tracking
- `SubagentStop` quality gate

**Phase 8 — Distribution (Module 10)**
- Git worktrees for parallel feature development
- Plugin bundling (`.claude-plugin/plugin.json`)
- Evaluation framework with fixtures and scoring

#### 4. Reference Docs Pattern (`context/` directory)
cc-self-train stores 18 reference documents in `context/` covering every CC feature. These are read on-demand by Claude when explaining features.

**Applicable to f-cat-new**: Create a `context/` directory with reference docs for:
- Trivy usage and output formats
- Gitleaks patterns and configuration
- Cloc output parsing
- Common vulnerability categories (OWASP, CWE)
- Code quality metrics definitions

#### 5. StatusLine Configuration
cc-self-train has a rich `statusLine` in settings.json that shows: user@host, MSYSTEM, working dir, git branch, model name, and context usage percentage. This uses `jq` to parse input JSON.

**Already applicable**: f-cat-new has jq available (v1.8.1). This pattern can be adopted directly.

### f-cat-new: Current State

#### What Exists
- **8 architecture rule files**: auth, cloudflare, database, forms, styling, sveltekit, testing, typescript — all SvelteKit/Cloudflare specific
- **6 research agents**: codebase-analyzer, codebase-locator, codebase-pattern-finder, thoughts-analyzer, thoughts-locator, web-search-researcher
- **8 CLI commands**: research-codebase, create-plan, iterate-plan, implement-plan, explain-feature, commit, describe_pr, issue
- **2 skills**: cut-a-release, explain-code
- **1 plugin**: research-plan-implement (with setup + workflow-guide skills)
- **1 SessionStart hook**: check-software.sh (checks trivy, gitleaks, cloc)
- **settings.json**: enables plugin, configures hook
- **settings.local.json**: permission allowlist

#### What's Missing for an Analysis Workflow Tool
1. **No application code** — no scanner, no rule engine, no reporter
2. **No analysis-specific skills** — `/scan`, `/security-scan`, `/generate-report`
3. **No analysis-specific agents** — security-analyzer, code-quality-analyzer, report-generator
4. **No target repo management** — no workflow to point at and analyze an external repo
5. **No report templates** — no output format for findings
6. **No context docs** — no reference documentation for the analysis tools
7. **No onboarding skill** — no `/start-review` equivalent
8. **CLAUDE.md is a stub** — needs project description, workflow documentation
9. **Rules are SvelteKit-specific** — need generalization or supplementation with language-agnostic analysis rules
10. **No persistence** — no database for tracking findings across reviews

### Mapping cc-self-train Patterns to f-cat-new

| cc-self-train Pattern | f-cat-new Equivalent | Status |
|----------------------|---------------------|--------|
| `/start` onboarding skill | `/start-review` | Not built |
| `context/` reference docs | `context/` for trivy, gitleaks, cloc docs | Not built |
| Sentinel file scanner | Trivy + Gitleaks + Cloc integration | Not built |
| Sentinel rule engine | Custom analysis rules (beyond tool defaults) | Not built |
| SessionStart hook (welcome) | SessionStart hook (check-software.sh) | **Exists** |
| StatusLine | StatusLine config | Not configured |
| `.claude/rules/` | `.claude/rules/` (8 files) | **Exists** (SvelteKit-specific) |
| Subagents (analyzer, test-writer, reporter) | Subagents (6 research agents) | **Partially exists** (research-focused, not analysis-focused) |
| `/doctor` diagnostic | `/doctor` diagnostic | Not built |
| `/recap` progress review | Review summary skill | Not built |
| MCP SQLite for persistence | MCP for findings storage | Not built |
| Evaluation framework | Analysis accuracy tracking | Not built |
| Plugin distribution | Plugin already scaffolded | **Exists** (research-plan-implement) |

## Architecture Documentation

### Proposed Architecture (Derived from cc-self-train Sentinel)

```
f-cat-new/
├── CLAUDE.md                     # Project description, analysis workflow docs
├── CLAUDE.local.md               # Per-user review state (gitignored)
├── README.md                     # Setup guide for Dev Eng users
├── context/                      # Reference docs for analysis tools
│   ├── trivy.txt                 # Trivy usage, output formats, severity levels
│   ├── gitleaks.txt              # Gitleaks patterns, custom rules
│   ├── cloc.txt                  # Cloc output parsing, language support
│   ├── owasp-top10.txt           # Common vulnerability categories
│   └── code-metrics.txt          # Complexity, maintainability definitions
├── reports/                      # Generated analysis reports (gitignored)
│   └── YYYY-MM-DD-<repo>/       # Per-review output
├── workspace/                    # Cloned target repos (gitignored)
├── .claude/
│   ├── settings.json             # Hooks, statusLine, plugin config
│   ├── hooks/
│   │   ├── check-software.sh     # Startup tool verification (exists)
│   │   └── welcome.js            # Welcome banner (new)
│   ├── rules/                    # Analysis conventions (exists, needs generalization)
│   ├── agents/
│   │   ├── security-analyzer.md  # Trivy + Gitleaks focused agent
│   │   ├── code-quality-analyzer.md  # Cloc + complexity agent
│   │   ├── report-generator.md   # Consolidates findings into reports
│   │   └── (existing 6 agents)   # Research agents stay
│   ├── skills/
│   │   ├── start-review/SKILL.md # Onboarding: pick repo, verify tools, init review
│   │   ├── scan/SKILL.md         # Run full analysis pipeline
│   │   ├── doctor/SKILL.md       # Environment diagnostic
│   │   └── (existing skills)     # cut-a-release, explain-code stay
│   ├── commands/
│   │   └── (existing 8 commands) # Research/plan commands stay
│   └── plugins/
│       └── research-plan-implement/  # Existing plugin stays
└── thoughts/
    └── shared/
        ├── research/             # Research documents
        └── plans/                # Implementation plans
```

## Open Questions

1. **Scope of analysis**: Should f-cat-new only orchestrate existing tools (trivy, gitleaks, cloc) or also include custom analysis rules like Sentinel's function-length/complexity checkers?

2. **Target repo handling**: Should the tool clone target repos into `workspace/`, analyze them in-place at their existing path, or support both?

3. **Report format**: Should reports be text/markdown, JSON, HTML, or all three? Sentinel supports all three via the reporter agent.

4. **Persistence**: Should findings be stored in SQLite (like Sentinel) for trend tracking across multiple reviews, or is each review standalone?

5. **Rules generalization**: The existing 8 rule files are SvelteKit/Cloudflare-specific. Should these be kept (for reviewing SvelteKit projects specifically), replaced with language-agnostic rules, or supplemented with additional rule sets?

6. **Multi-language support**: Should the tool be able to analyze repos in any language, or focus on a specific stack?

7. **Integration with existing research-plan-implement plugin**: Should the analysis workflow be a new plugin or extend the existing one?

8. **CI/CD integration**: Should f-cat-new produce output consumable by CI systems (exit codes, SARIF format, etc.)?
