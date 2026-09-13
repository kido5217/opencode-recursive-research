#!/usr/bin/env bash
# Verification harness for the opencode recursive-research port.
#
# Checks, in order:
#   1. the skill installs via the `skills` CLI into a throwaway project
#   2. opencode v1 (1.18.30) discovers it
#   3. opencode v2 (2.0.2) advertises it
#   4. an end-to-end smoke run executes Phase 1 and writes the workspace
#
# Usage: scripts/verify.sh
# Env:   VERIFY_MODEL=<provider/model>   (default: deepseek/deepseek-v4-flash)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/recursive-research-verify.XXXXXX")"
MODEL="${VERIFY_MODEL:-deepseek/deepseek-v4-flash}"
SKILL_ID="recursive-research"
PASS=0
FAIL=0

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 2; }; }

need npx
need opencode
need opencode2

echo "== 1. Install via the skills CLI =="
( cd "$WORKDIR" && npx --yes skills add "$REPO_ROOT" --skill "$SKILL_ID" -a opencode --copy -y >/dev/null 2>&1 )
if [[ -f "$WORKDIR/.agents/skills/$SKILL_ID/SKILL.md" ]]; then
  ok "installed to .agents/skills/$SKILL_ID/SKILL.md"
else
  bad "skill was not installed by the skills CLI"
fi

echo "== 2. Discovery on opencode v1 (1.18.30) =="
# Redirect to a file: piping into grep can SIGPIPE the producer under pipefail, and
# command substitution can capture a partial stream for this large JSON payload.
( cd "$WORKDIR" && opencode debug skill >"$WORKDIR/v1-skills.json" 2>/dev/null || true )
if grep -q "\"name\": \"$SKILL_ID\"" "$WORKDIR/v1-skills.json"; then
  ok "opencode debug skill lists $SKILL_ID"
else
  bad "opencode (v1) did not list $SKILL_ID"
fi

echo "== 3. Discovery on opencode v2 (2.0.2) =="
V2_OK=0
for _ in 1 2 3; do
  V2_OUT="$( cd "$WORKDIR" && opencode2 run --standalone --model "$MODEL" \
    "Reply with EXACTLY the text between <available_skills> and </available_skills> in your system prompt, verbatim. If there is no such block, reply NONE." 2>/dev/null || true )"
  if grep -q "<id>$SKILL_ID</id>" <<<"$V2_OUT"; then V2_OK=1; break; fi
done
if [[ "$V2_OK" -eq 1 ]]; then
  ok "opencode2 run advertises $SKILL_ID"
else
  bad "opencode2 (v2) did not advertise $SKILL_ID after 3 attempts"
fi

echo "== 4. End-to-end smoke run (Phase 1 workspace) =="
SMOKE_PROMPT="You are running non-interactively. Invoke the $SKILL_ID skill now. Answers to Phase 0: seed='opencode port smoke test'; mode=web; no local paths; no prioritized or excluded sources; cycle cap=1. Do NOT ask questions and do NOT perform any web searches. Execute Phase 1 only: create memory/research/<slug>/ with the initial files (state.md, threads.md, sources-tier-1.md, sources-tier-2.md, sources-tier-3.md, sources-rejected.md, findings.md). Then stop."
EXPECTED=(state.md threads.md sources-tier-1.md sources-tier-2.md sources-tier-3.md sources-rejected.md findings.md)
SMOKE_OK=0
for _ in 1 2; do
  ( cd "$WORKDIR" && opencode2 run --standalone --auto --model "$MODEL" "$SMOKE_PROMPT" >/dev/null 2>&1 || true )
  SMOKE_DIR="$(find "$WORKDIR/memory/research" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1 || true)"
  [[ -n "$SMOKE_DIR" ]] || continue
  missing=0
  for f in "${EXPECTED[@]}"; do [[ -f "$SMOKE_DIR/$f" ]] || missing=$((missing + 1)); done
  if [[ "$missing" -eq 0 ]]; then SMOKE_OK=1; break; fi
done
if [[ "$SMOKE_OK" -eq 1 ]]; then
  ok "smoke run created all 7 initial files under $(basename "$SMOKE_DIR")"
else
  bad "smoke run did not create the full Phase 1 workspace"
fi

echo
echo "Result: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
