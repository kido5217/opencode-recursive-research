# AGENTS.md

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in this repo, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles map to same-named labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Git

The `main` branch is protected on GitHub: direct pushes, force pushes, and deletions are blocked, and the rule applies to admins too. Make changes on a branch and merge via a pull request.
