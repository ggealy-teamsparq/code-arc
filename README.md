# code-arc

## Hooks

Claude Code is configured with startup hooks that run automatically at the beginning of each new conversation session.

### Software Check

A `SessionStart` hook verifies that the following tools are installed on the developer's machine:

- **Trivy** — container and filesystem vulnerability scanner
- **Gitleaks** — secret detection in git repos
- **Cloc** — count lines of code
- **gh** — GitHub CLI for PR and issue management

The hook is defined in `.claude/hooks/check-software.sh` and configured in `.claude/settings.json`. When a new session starts, it reports the installed version of each tool and warns about any that are missing.

### Adding New Checks

To check for additional tools, add them to the `for tool in ...` loop in `.claude/hooks/check-software.sh`.
