#!/usr/bin/env zsh
#
# Focused suite for stage858. It consumes stage857 and records owner-local
# in-memory state-store commit snapshot facts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE858_TMPDIR:-/private/tmp/cjgui-stage857-stage860/stage858}"
SUITE_PACKET="$TMP_DIR/stage858-owner-local-text-input-state-store-commit-snapshot-suite.packet"
STAGE857_SUITE_PACKET="${CJGUI_STAGE858_INPUT_PACKET:-${CJGUI_STAGE857_OWNER_LOCAL_TEXT_INPUT_COMMIT_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage857-stage860/stage857/stage857-owner-local-text-input-commit-dry-run-suite.packet}}"
STAGE857_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage857_owner_local_text_input_commit_dry_run_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage858_owner_local_text_input_state_store_commit_snapshot_owner.sh"
OWNER_LOG="$TMP_DIR/stage858-owner-local-text-input-state-store-commit-snapshot-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage858 owner-local text input state-store commit snapshot suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE857_SUITE_PACKET" ]] || ! grep -F "stage857_owner_local_text_input_commit_dry_run_suite_passed=true" "$STAGE857_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE857_TMPDIR="$TMP_DIR/stage857" zsh "$STAGE857_SUITE_SCRIPT" >/dev/null
  STAGE857_SUITE_PACKET="$TMP_DIR/stage857/stage857-owner-local-text-input-commit-dry-run-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage857_owner_local_text_input_commit_dry_run_consumed=true" \
  "stage856_text_input_commit_runtime_manager_consumed_transitively=true" \
  "owner_local_text_input_state_store_commit_snapshot_materialized=true" \
  "owner_local_text_input_committed_value_materialized=true" \
  "owner_local_text_input_state_store_commit_receipt_materialized=true" \
  "owner_local_text_input_commit_rollback_snapshot_materialized=true" \
  "owner_local_text_input_state_store_commit_snapshot_bound_to_stage857_dry_run=true" \
  "owner_local_state_store_in_memory_only=true" \
  "owner_local_text_input_commit_first_slice_materialized=true" \
  "owner_local_text_input_commit_applied=true" \
  "stage859_owner_local_text_input_commit_result_surface_prepared=true" \
  "text_input_commit_committed=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage857_owner_local_text_input_commit_dry_run_suite_passed=true" \
  "owner_local_text_input_commit_dry_run_executed=true" \
  "stage858_owner_local_text_input_state_store_commit_snapshot_prepared=true" \
  "text_input_commit_committed=false"; do
  require_file_fact "$STAGE857_SUITE_PACKET" "$fact"
done

{
  echo "stage858_owner_local_text_input_state_store_commit_snapshot_suite_version=1"
  echo "stage857_suite_packet=$STAGE857_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage859_owner_local_text_input_commit_result_surface_after_stage858"
  echo "stage858_owner_local_text_input_state_store_commit_snapshot_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage858 owner-local text input state-store commit snapshot suite: route_classification=owner_local_text_input_state_store_commit_snapshot"
echo "cjgui stage858 owner-local text input state-store commit snapshot suite: suite_packet_path=$SUITE_PACKET"
