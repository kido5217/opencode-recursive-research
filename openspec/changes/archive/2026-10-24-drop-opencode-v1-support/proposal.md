# Proposal

## Why

The repo claims to support opencode v1 and v2, but the only v1-era mechanism left — `metadata.opencode/slash: "false"` in the skill frontmatter — parses to nothing on the current runtime: it appears 0 times in the opencode 2.1.4 binary and is absent from the v2 skills docs (which list only `opencode/autoinvoke`). The README paragraph built on it ("slash-invocation drops the trailing arguments") is unverified, and a live probe showed `opencode run` delivering the flags verbatim; the live `/api/command` registry for this project contains no skill-sourced entries, so v2 does not register skills as slash commands at all. Keeping a dead opt-out plus a stale comparison is sediment; we support v2 only.

## What Changes

- Remove `opencode/slash: "false"` from `skills/recursive-research/SKILL.md` frontmatter (dead v1 key).
- Rewrite README.md §Usage invocation note as a v2-only statement: invocation is a message (typed line or `@recursive-research` mention), the skill reads flags from the invocation text; drop the "exactly as on opencode v1" comparison and state what v2 does instead: skills are not registered as slash commands (observed: `/api/command` for this project returns no skill-sourced entries), and flags arrive verbatim in the invocation message (observed on `opencode run`; the TUI's handling of slash-prefixed text is undocumented and therefore not claimed).
- Bump skill version 3.0.0 → 3.0.1 (metadata/docs only; no behavior change).
- No other v1 residue: install paths, PRIVACY, and verify.sh already speak v2 (`.agents/skills/` and `.opencode/skills/` are documented v2 discovery sources; the harness probes the renamed v2 binary).

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

(none — `research-workspace` requirements are about path/flag semantics, unchanged; the change deletes dead metadata and restates docs, so no spec-level behavior changes. `skip_specs: true` set in `.openspec.yaml`.)

## Impact

- `skills/recursive-research/SKILL.md` — frontmatter (one key, one version value).
- `README.md` — the slash-command paragraph (line ~80) and the "Invoke with" line (~65).
- No code, no spec deltas, no privacy-relevant behavior; archive artifacts and upstream version mentions are historical and untouched.
