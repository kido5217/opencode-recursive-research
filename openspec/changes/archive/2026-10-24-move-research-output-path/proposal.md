# Proposal

## Why

The run workspace lives under `memory/research/<slug>/`, a path inherited verbatim from the upstream Spanish layout (`memoria/investigaciones/`); the `memory/` namespace carries no rationale. Research output is a project artifact, so it should sit in a plain `research/` folder where the skill runs, and users should be able to redirect it with `--target`.

## What Changes

- **BREAKING** Workspace root moves from `memory/research/<slug>/` to `research/` in the invocation directory. The slug is dropped from the path; it survives only as run metadata (`state.md`, `registry.json`, messages). The path identifies the run.
- **BREAKING** `--resume <slug>` becomes `--resume` (no argument): it resumes the run at the active target. `--list` is repurposed from "enumerate runs" to "summarize the run at the active target".
- New `--target <dir>` invocation flag: overrides the default `research/` root for new, resume, and list alike; created when absent.
- New-run into an occupied target (a `state.md` exists there): the skill reports the occupant (seed, status, last modified) and offers resume / overwrite / pick another target. It never destroys an existing run unasked.
- Clean break: no fallback reads of `memory/research/`; README and PRIVACY carry a "move your old folder" note.

## Capabilities

### New Capabilities

- `research-workspace`: where a run stores its artifacts, how the target directory is chosen or overridden, and how resume/list/occupation behave around it.

### Modified Capabilities

(none — the project has no specs yet)

## Impact

- `skills/recursive-research/SKILL.md` — all 10 path references, Phase 0/1 workspace logic, pause message, `--resume`/`--list` modes, generated-files tree, invocation example, `--target` flag; version bump.
- `README.md` (2 refs), `PRIVACY.md` (3 refs), `docs/artifact-name-map.md` (mapping row).
- `scripts/verify.sh` — smoke test locates the workspace directly under `$WORKDIR/research`.
- Doc edits follow the `writing-for-agents` skill: one authoritative statement of the path rule, positive phrasing, pointer wording kept in sync with the new flag set.
