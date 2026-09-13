# AGENTS.md

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in this repo, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles map to same-named labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Git

The `main` branch is protected on GitHub: force pushes and deletions are blocked. Make changes on a branch and open a pull request; do not force-push `main`.
