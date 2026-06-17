#!/usr/bin/env zsh
#
# Focused suite for stage854. It consumes stage853 and records rollback/not-published facts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE854_TMPDIR:-/private/tmp/cjgui-stage853-stage856/stage854}"
SUITE_PACKET="$TMP_DIR/stage854-text-input-commit-rollback-snapshot-suite.packet"
STAGE853_SUITE_PACKET="${CJGUI_STAGE854_INPUT_PACKET:-${CJGUI_STAGE853_TEXT_INPUT_COMMIT_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage853-stage856/stage853/stage853-text-input-commit-preflight-suite.packet}}"
STAGE853_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage853_text_input_commit_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage854_text_input_commit_rollback_snapshot_owner.sh"
OWNER_LOG="$TMP_DIR/stage854-text-input-commit-rollback-snapshot-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage854 text input commit rollback snapshot suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE853_SUITE_PACKET" ]] || ! grep -F "stage853_text_input_commit_preflight_suite_passed=true" "$STAGE853_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE853_TMPDIR="$TMP_DIR/stage853" zsh "$STAGE853_SUITE_SCRIPT" >/dev/null
  STAGE853_SUITE_PACKET="$TMP_DIR/stage853/stage853-text-input-commit-preflight-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage853_text_input_commit_preflight_consumed=true" \
  "text_input_rollback_snapshot_materialized=true" \
  "text_input_not_published_receipt_materialized=true" \
  "owner_local_text_input_write_set_candidate_materialized=true" \
  "file_browser_text_input_commit_rollback_surface_materialized=true" \
  "stage855_text_input_commit_inspection_surface_prepared=true" \
  "text_input_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage853_text_input_commit_preflight_suite_passed=true" \
  "text_input_commit_candidate_ledger_materialized=true" \
  "stage854_text_input_commit_rollback_snapshot_prepared=true" \
  "text_input_commit_committed=false"; do
  require_file_fact "$STAGE853_SUITE_PACKET" "$fact"
done

{
  echo "stage854_text_input_commit_rollback_snapshot_suite_version=1"
  echo "stage853_suite_packet=$STAGE853_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage854_text_input_commit_rollback_snapshot_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage854 text input commit rollback snapshot suite: route_classification=text_input_commit_rollback_snapshot"
echo "cjgui stage854 text input commit rollback snapshot suite: suite_packet_path=$SUITE_PACKET"
