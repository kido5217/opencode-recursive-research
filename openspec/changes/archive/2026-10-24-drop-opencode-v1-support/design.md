# Design

## Context

See proposal.md for motivation. One metadata decision and one wording dependency.

## Goals / Non-Goals

**Goals:**
- Leave the skill loadable, advertised, and flag-capable on v2 only.

**Non-Goals:**
- No new frontmatter fields beyond deleting the dead one; no behavior edits to Phase 0.

## Decisions

- **Delete `opencode/slash: "false"` outright rather than translate it to `opencode/autoinvoke: false`.** The keys are not equivalent: `autoinvoke: false` hides the skill from the model's available list (killing description auto-trigger, which the README advertises) while the deleted key only ever aimed at slash registration. v2 offers no per-skill slash opt-out, so there is nothing to translate to; the alternative rejected the feature.
- **README wording is committed only after the 2.1 observation.** The docs-derived claim "v2 appends arguments after the skill body" (commands Fallback rule + the `run` probe) is inference for the TUI path; the task makes the one-line rewrite conditional on what the user actually sees, so the published doc states a fact, not a guess.

## Risks / Trade-offs

- If the TUI check shows v2 registers the skill as a slash command and drops args → README keeps recommending the typed-message path anyway; the only difference is one sentence's claim. No code consequence.
- Removing the key changes v1 behavior for any hypothetical v1 user (opt-out disappears) — accepted; v1 support is what this change drops.
