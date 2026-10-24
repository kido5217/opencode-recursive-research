# Tasks

## 1. SKILL.md — new workspace grammar

- [ ] 1.1 Define the active-target rule once in Phase 0/1 (default `research/`, `--target <dir>` override resolved against the invocation directory, created-with-notice) and add the `--target` branch to the invocation-reading list; verify by re-reading Phase 0/1 and confirming every later path mention points at this single definition.
- [ ] 1.2 Add the occupied-target prompt to Phase 1 (test = `state.md` present; report occupant seed/status/last-modified; offer resume / overwrite / new target; no destruction before the user chooses) and verify against the spec scenario "New run over an open run" in `specs/research-workspace/spec.md`.
- [ ] 1.3 Rewrite `--resume` (no slug argument; active target only; no-run → report and stop) and `--list` (summarize the single run at the active target) sections and verify each spec scenario under "Resume without a slug argument" and "List summarizes the active target" maps to a sentence in the new text.
- [ ] 1.4 Replace all remaining `memory/research/<slug>/` strings — Phase 3 fixture capture, 5.5 checkpoint, pause message, §Generated files tree, §Fixture registry, invocation example — with the target-root form, bump frontmatter `version` to `3.0.0`, and verify `grep -c 'memory/research' skills/recursive-research/SKILL.md` returns nothing while `grep -c '\-\-target'` returns ≥ 3.

## 2. User-facing docs

- [ ] 2.1 Update `README.md` (§Generated files, §Fixtures & the report): new path, `--target` in the usage/flags text, and the clean-break note to move `memory/research/` yourself; verify the two old-path references are gone and a reader can find `--target` from the quickstart.
- [ ] 2.2 Update `PRIVACY.md` (§Data we write, §Where your data lives, §Deleting everything): `research/` wording and the new `rm -rf` line; verify no `memory/research` remains.
- [ ] 2.3 Update `docs/artifact-name-map.md` mapping row to `memoria/investigaciones/<slug>/` → `research/` with a note that the slug segment is retired; verify the row matches SKILL.md §Generated files.

## 3. Smoke-test script

- [ ] 3.1 Point `scripts/verify.sh` at `$WORKDIR/research` (drop the `find`; test the dir directly) and pin the smoke prompt to an empty workdir so the occupied-target branch stays out of scope; verify by running `bash scripts/verify.sh` end to end with all checks green.

## 4. Integration check

- [ ] 4.1 Repo-wide sweep: `grep -rn 'memory/research'` (excluding `openspec/changes/`) returns nothing, and `openspec validate move-research-output-path --strict` passes; fixes here land in the owning file, not a new doc.

## Workflow follow-up

- Review the diff against the spec scenarios, then branch + PR per AGENTS.md (main is protected).
- Archive the change with `/opsx-archive` after merge.
