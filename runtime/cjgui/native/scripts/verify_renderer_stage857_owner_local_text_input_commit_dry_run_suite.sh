#!/usr/bin/env zsh
#
# Focused suite for stage857. It consumes stage856 and records the owner-local
# text-input commit dry-run executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE857_TMPDIR:-/private/tmp/cjgui-stage857-stage860/stage857}"
SUITE_PACKET="$TMP_DIR/stage857-owner-local-text-input-commit-dry-run-suite.packet"
STAGE856_SUITE_PACKET="${CJGUI_STAGE857_INPUT_PACKET:-${CJGUI_STAGE856_TEXT_INPUT_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage853-stage856/stage856/stage856-text-input-commit-runtime-manager-suite.packet}}"
STAGE856_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage856_text_input_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage857_owner_local_text_input_commit_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage857-owner-local-text-input-commit-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage857 owner-local text input commit dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE856_SUITE_PACKET" ]] || ! grep -F "stage856_text_input_commit_runtime_manager_suite_passed=true" "$STAGE856_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE856_TMPDIR="$TMP_DIR/stage856" zsh "$STAGE856_SUITE_SCRIPT" >/dev/null
  STAGE856_SUITE_PACKET="$TMP_DIR/stage856/stage856-text-input-commit-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage856_text_input_commit_runtime_manager_consumed=true" \
  "owner_local_text_input_commit_dry_run_executor_materialized=true" \
  "owner_local_text_input_commit_application_plan_materialized=true" \
  "owner_local_text_input_commit_receipt_materialized=true" \
  "owner_local_text_input_commit_rollback_token_materialized=true" \
  "owner_local_text_input_commit_dry_run_bound_to_stage856_runtime_manager=true" \
  "owner_local_text_input_commit_dry_run_in_memory_only=true" \
  "owner_local_text_input_commit_dry_run_executed=true" \
  "stage858_owner_local_text_input_state_store_commit_snapshot_prepared=true" \
  "owner_local_commit_first_slice_ready=true" \
  "text_input_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage856_text_input_commit_runtime_manager_suite_passed=true" \
  "owner_local_commit_first_slice_ready=true" \
  "stage857_owner_local_text_input_commit_dry_run_prepared=true" \
  "text_input_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE856_SUITE_PACKET" "$fact"
done

{
  echo "stage857_owner_local_text_input_commit_dry_run_suite_version=1"
  echo "stage856_suite_packet=$STAGE856_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage858_owner_local_text_input_state_store_commit_snapshot_after_stage857"
  echo "stage857_owner_local_text_input_commit_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage857 owner-local text input commit dry-run suite: route_classification=owner_local_text_input_commit_dry_run"
echo "cjgui stage857 owner-local text input commit dry-run suite: suite_packet_path=$SUITE_PACKET"
