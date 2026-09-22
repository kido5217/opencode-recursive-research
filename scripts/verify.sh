#!/usr/bin/env bash
# Verification harness for the opencode recursive-research port.
#
# Checks, in order:
#   1. the skill installs via the `skills` CLI into a throwaway project
#   2. opencode v2 advertises it
#   3. an end-to-end smoke run writes the workspace, a fixture + registry, and report.md
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

echo "== 1. Install via the skills CLI =="
( cd "$WORKDIR" && npx --yes skills add "$REPO_ROOT" --skill "$SKILL_ID" -a opencode --copy -y >/dev/null 2>&1 )
if [[ -f "$WORKDIR/.agents/skills/$SKILL_ID/SKILL.md" ]]; then
  ok "installed to .agents/skills/$SKILL_ID/SKILL.md"
else
  bad "skill was not installed by the skills CLI"
fi

echo "== 2. Advertised by opencode v2 =="
V2_OK=0
for _ in 1 2 3; do
  V2_OUT="$( cd "$WORKDIR" && opencode run --standalone --model "$MODEL" \
    "Reply with EXACTLY the text between <available_skills> and </available_skills> in your system prompt, verbatim. If there is no such block, reply NONE." 2>/dev/null || true )"
  if grep -q "<id>$SKILL_ID</id>" <<<"$V2_OUT"; then V2_OK=1; break; fi
done
if [[ "$V2_OK" -eq 1 ]]; then
  ok "opencode run advertises $SKILL_ID"
else
  bad "opencode (v2) did not advertise $SKILL_ID after 3 attempts"
fi

echo "== 3. End-to-end smoke run (fixtures + report) =="
SMOKE_PROMPT="You are running non-interactively. Invoke the $SKILL_ID skill now. Answers to Phase 0: seed='opencode port smoke test'; mode=web; no local paths; no prioritized or excluded sources; cycle cap=1; retention threshold=5 MB. Do NOT ask questions and do NOT perform any web searches. Use this single fabricated source instead of searching: url=https://example.com, title='Example Domain', tier=2, thread='smoke'. Execute Phase 1; run one cycle that (a) writes a fixture at fixtures/webpage/<id>/page.md (text 'Example Domain') and fixtures/webpage/<id>/raw.html, (b) writes a searchset fixture fixtures/searchset/<id>/results.json containing that one result, (c) updates fixtures/registry.json; then run Phase 6 to write report.md. Stop once report.md exists."
EXPECTED=(state.md threads.md sources-tier-1.md sources-tier-2.md sources-tier-3.md sources-rejected.md findings.md report.md fixtures/registry.json fixtures/registry.schema.json)
SMOKE_OK=0
for _ in 1 2 3; do
  ( cd "$WORKDIR" && opencode run --standalone --auto --model "$MODEL" "$SMOKE_PROMPT" >/dev/null 2>&1 || true )
  SMOKE_DIR="$(find "$WORKDIR/memory/research" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1 || true)"
  [[ -n "$SMOKE_DIR" ]] || continue
  missing=0
  for f in "${EXPECTED[@]}"; do [[ -f "$SMOKE_DIR/$f" ]] || missing=$((missing + 1)); done
  if [[ "$missing" -eq 0 ]]; then SMOKE_OK=1; break; fi
done
if [[ "$SMOKE_OK" -eq 1 ]]; then
  ok "smoke run created the workspace, fixtures registry, and report.md under $(basename "$SMOKE_DIR")"
else
  bad "smoke run did not create the full workspace (${missing:-?} of ${#EXPECTED[@]} files missing)"
fi

echo
echo "Result: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
