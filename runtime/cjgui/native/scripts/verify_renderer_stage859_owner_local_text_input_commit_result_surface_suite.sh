#!/usr/bin/env zsh
#
# Focused suite for stage859. It consumes stage858 and records demo-host
# owner-local text-input commit result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE859_TMPDIR:-/private/tmp/cjgui-stage857-stage860/stage859}"
SUITE_PACKET="$TMP_DIR/stage859-owner-local-text-input-commit-result-surface-suite.packet"
STAGE858_SUITE_PACKET="${CJGUI_STAGE859_INPUT_PACKET:-${CJGUI_STAGE858_OWNER_LOCAL_TEXT_INPUT_STATE_STORE_COMMIT_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage857-stage860/stage858/stage858-owner-local-text-input-state-store-commit-snapshot-suite.packet}}"
STAGE858_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage858_owner_local_text_input_state_store_commit_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage859_owner_local_text_input_commit_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage859-owner-local-text-input-commit-result-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage859 owner-local text input commit result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE858_SUITE_PACKET" ]] || ! grep -F "stage858_owner_local_text_input_state_store_commit_snapshot_suite_passed=true" "$STAGE858_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE858_TMPDIR="$TMP_DIR/stage858" zsh "$STAGE858_SUITE_SCRIPT" >/dev/null
  STAGE858_SUITE_PACKET="$TMP_DIR/stage858/stage858-owner-local-text-input-state-store-commit-snapshot-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage858_owner_local_text_input_state_store_commit_snapshot_consumed=true" \
  "stage857_owner_local_text_input_commit_dry_run_consumed_transitively=true" \
  "owner_local_text_input_commit_result_row_model_materialized=true" \
  "owner_local_text_input_committed_value_rows_materialized=true" \
  "owner_local_text_input_rollback_rows_materialized=true" \
  "owner_local_text_input_not_published_boundary_banner_materialized=true" \
  "todo_owner_local_text_input_commit_result_surface_materialized=true" \
  "settings_owner_local_text_input_commit_result_surface_materialized=true" \
  "ai_generated_settings_owner_local_text_input_commit_result_surface_materialized=true" \
  "chat_composer_owner_local_text_input_commit_result_surface_materialized=true" \
  "file_browser_owner_local_text_input_commit_result_surface_materialized=true" \
  "owner_local_text_input_commit_result_surface_bound_to_stage858_snapshot=true" \
  "owner_local_text_input_commit_applied=true" \
  "stage860_owner_local_text_input_commit_runtime_manager_prepared=true" \
  "text_input_commit_committed=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage858_owner_local_text_input_state_store_commit_snapshot_suite_passed=true" \
  "owner_local_text_input_commit_first_slice_materialized=true" \
  "owner_local_text_input_commit_applied=true" \
  "stage859_owner_local_text_input_commit_result_surface_prepared=true"; do
  require_file_fact "$STAGE858_SUITE_PACKET" "$fact"
done

{
  echo "stage859_owner_local_text_input_commit_result_surface_suite_version=1"
  echo "stage858_suite_packet=$STAGE858_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage860_owner_local_text_input_commit_runtime_manager_after_stage859"
  echo "stage859_owner_local_text_input_commit_result_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage859 owner-local text input commit result surface suite: route_classification=owner_local_text_input_commit_result_surface"
echo "cjgui stage859 owner-local text input commit result surface suite: suite_packet_path=$SUITE_PACKET"
