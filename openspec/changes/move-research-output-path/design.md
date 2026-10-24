# Design

## Context

See `proposal.md` for motivation. `SKILL.md` is the run-time source of truth; 18 path references sit across five files (`SKILL.md` ×10, `README.md` ×2, `PRIVACY.md` ×3, `scripts/verify.sh` ×1, `docs/artifact-name-map.md` ×1). The workspace layout itself (file set, fixture registry, relative report links) is untouched — only its address changes.

## Goals / Non-Goals

**Goals:**
- One authoritative statement of the target rule in `SKILL.md`; every other mention points at it or echoes it verbatim.
- Invocation grammar that stays a flat flag set on the first line: `--resume`, `--list`, `--target <dir>`, combinable.

**Non-Goals:**
- No change to the fixture registry format: `run.slug` stays a required-in-spirit metadata field, still populated, so `registry.schema.json` and its `schema_version` are unchanged.
- No migration tooling — clean break; the user moves or deletes `memory/research/` themselves.
- No multi-run-per-project layout (the whole point is one run per target directory).

## Decisions

- **Move the whole run root rather than export only `report.md`.** `report.md` links fixture bodies by relative path; a split layout would break the links or copy fixtures into two homes and fork resume state. Single directory keeps every requirement in `specs/research-workspace` satisfiable with one path constant.
- **Occupation test = presence of `state.md`.** Same predicate resume and list already use; no new marker file, one meaning in one place. Chosen over a lock/journal file (unneeded complexity for a sequential skill) and over testing for `report.md` (misses open runs).
- **`--target <dir>` resolves relative to the invocation directory**; absolute paths pass through. Documented in one Phase 0 line rather than repeated per mode — mode sections say "the active target", defined once.
- **Version bump to 3.0.0.** The path move, the `--resume` signature change, and the `--list` semantics change are all user-visible breaking changes; semver-major names that honestly. A minor bump would hide them.
- **Doc rewrites follow the `writing-for-agents` skill:** the Phase 0 router gains a `--target` branch with one trigger phrase each; the "I am creating it" narration is reworded positively for `research/`; each mode section keeps its completion criteria as-is (they are path-agnostic); duplicate path spellings in prose collapse to the tree in §Generated files as the single source.
- **`verify.sh` checks `$WORKDIR/research` directly** (`EXPECTED` files resolved under it, `find` replaced by a plain test). The smoke prompt pins a fresh temp WORKDIR, so the occupied-target branch never fires there; a second smoke variant is unnecessary.

## Risks / Trade-offs

- `research/` may collide with an existing project folder of the same name → benign: the skill adds its files beside existing content; the Phase 1 notice already names the folder it creates.
- One run per default target means a second default run always meets the occupation prompt → accepted; `--target` is the intended answer and the prompt is the guardrail.
- Clean break strands legacy folders with no fallback → README/PRIVACY carry the move note; `--list` on the new path reporting "no run" is the discoverable symptom.

## Migration Plan

1. Land docs + script changes in one commit; the skill is dataless, so rollback is `git revert` — legacy runs untouched on disk still live under `memory/research/` until moved.
2. Release note (README "Generated files" + PRIVACY "Data we write") states: move `memory/research/<slug>/` to wherever you want it; the next version reads only `--target`/`research/`.

## Open Questions

(none)
