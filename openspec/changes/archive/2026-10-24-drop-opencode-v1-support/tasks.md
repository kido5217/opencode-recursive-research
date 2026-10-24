# Tasks

## 1. Drop the dead key

- [x] 1.1 Remove the `opencode/slash: "false"` line from `skills/recursive-research/SKILL.md` frontmatter and bump `version` to `3.0.1`; verify `grep -c 'opencode/slash' skills/recursive-research/SKILL.md` returns nothing and the frontmatter still parses (skill loads in a fresh session).

## 2. Observe the real TUI behavior

- [x] 2.1 In a throwaway directory with the skill installed, type `/recursive-research --list` in the v2.1.4 TUI and record which happened: the skill answers the list summary (flags arrived) or falls into the Phase 0 seed question (flags dropped); verification is the observed reply, noted in this file before editing README.
  - OBSERVED (2026-10-24, headless instead of keystrokes): live server `GET /api/command` scoped to the project returned 14 commands (built-ins, global `ctx-*`, project `opsx-*` from `.opencode/commands/`) — no skill-sourced entries. Skills are not registered as slash commands on v2.1.4, so `/recursive-research` is plain text in a user message; the `run` probe already showed such flags arrive verbatim. TUI check not needed.

## 3. Rewrite the invocation note

- [x] 3.1 Rewrite `README.md` §Usage paragraph (currently the "On opencode v2 the skill is deliberately not registered..." text) to match the observation from 2.1, stating v2-only facts: invocation by typed message, `@recursive-research` mention, or slash command, and how arguments arrive; verify no sentence mentions v1 or the removed key, and the "Invoke with" line above it names the same paths.
- [x] 3.2 If 2.1 showed flags dropped, extend the same rewrite to recommend the message path for flag-carrying invocations; if preserved, verify the README usage block drops its "type as a normal message" hedge and the `metadata.opencode/slash` explanation is gone from every non-archive doc (`grep -rIn 'opencode/slash' --exclude-dir=openspec --exclude-dir=.git .` returns nothing).

## 4. Integration check

- [x] 4.1 Run `bash scripts/verify.sh` (no code path changed, but the harness installs the edited SKILL.md) and `openspec validate drop-opencode-v1-support --strict`; both must pass.

## Workflow follow-up

- Review the diff, branch + PR per AGENTS.md (main is protected).
- Archive the change with `/opsx-archive` after merge.
