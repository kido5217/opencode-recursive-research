# Spec Delta

## Purpose

Defines where a recursive-research run stores its workspace and artifacts, how the target directory is chosen or overridden at invocation, and how resume, list, and occupied-target behavior relate to that directory.

## ADDED Requirements

### Requirement: Default workspace location
A run SHALL store its entire workspace — state, checkpoints, sources, findings, fixtures, and `report.md` — directly under a `research/` folder in the directory the skill is invoked from, with no per-run subdirectory. The skill SHALL create the folder when absent and say so before writing.

#### Scenario: First run in a clean project
- **WHEN** a new run starts in a directory with no `research/` folder
- **THEN** the skill creates `research/`, notifies the user, and writes `state.md` and the other initial files directly inside it

#### Scenario: Report lands at the root of the target
- **WHEN** a run closes
- **THEN** `report.md` exists at `<target>/report.md` and its fixture links resolve relative to that directory

### Requirement: Target override flag
The invocation SHALL accept `--target <dir>` to replace the default `research/` root. The flag applies identically to new runs, `--resume`, and `--list`. A missing target directory is created with the same notification as the default.

#### Scenario: Custom target for a new run
- **WHEN** the user invokes the skill with `--target docs/deep-dive`
- **THEN** the workspace is `docs/deep-dive/` and nothing is written under `research/`

#### Scenario: Resume honors the target
- **WHEN** the user invokes `--resume --target docs/deep-dive`
- **THEN** only `docs/deep-dive/` is considered, and a run found in `research/` is not resumed

### Requirement: Run identity is the path
The run's identity SHALL be its target directory. The slug remains generated from the seed and recorded as metadata in `state.md` and `fixtures/registry.json`, but SHALL NOT appear in any workspace path.

#### Scenario: Slug survives as metadata
- **WHEN** a run with seed "episodic memory in humans" starts with the default target
- **THEN** `state.md` records the slug `episodic-memory-in-humans` while all files live directly under `research/`

### Requirement: Resume without a slug argument
`--resume` SHALL take no slug argument and SHALL resume the run at the active target. When the active target holds no workspace (`state.md` absent), the skill SHALL report that plainly and stop; it SHALL NOT search other directories.

#### Scenario: Resume an open run
- **WHEN** the user invokes `--resume` on a target holding an open `state.md`
- **THEN** the skill rebuilds metrics from that workspace and continues the loop

#### Scenario: Resume with nothing to resume
- **WHEN** the user invokes `--resume` on an empty target
- **THEN** the skill states no run exists at that path and stops

### Requirement: List summarizes the active target
`--list` SHALL report a summary of the single run at the active target — slug, seed, cycles completed, status, fixture count, and whether `report.md` exists — and SHALL NOT enumerate sibling run directories. An empty target yields a one-line "no run at this target" result.

#### Scenario: List a closed run
- **WHEN** the user invokes `--list` on a target holding a closed run
- **THEN** the summary shows its status as closed and offers to start a new run

### Requirement: Occupied target prompts before any new run
When a new run is started and the target already holds a workspace (`state.md` present), the skill SHALL report the occupant's seed, status, and last modification, then offer resume, overwrite (delete the existing workspace), or a different `--target`. The skill SHALL NOT delete or overwrite occupant files before the user chooses.

#### Scenario: New run over an open run
- **WHEN** the user starts a new run into a target whose `state.md` shows an open run
- **THEN** the skill presents the occupant's summary and waits for resume / overwrite / new target

#### Scenario: Overwrite proceeds destructively only on request
- **WHEN** the user chooses overwrite
- **THEN** the skill clears the target directory and starts the new run in it

### Requirement: Clean break from the legacy path
The skill SHALL NOT read from or write to `memory/research/`. Documentation SHALL tell users to move or delete a legacy `memory/research/` folder themselves.

#### Scenario: Legacy folder is ignored
- **WHEN** a project still contains `memory/research/` from an earlier version and a run is resumed
- **THEN** the resume considers only the active target and reports no run there
