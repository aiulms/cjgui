#!/usr/bin/env zsh
#
# Focused suite for stage807. It consumes stage806 and records demo-host review history surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE807_TMPDIR:-/private/tmp/cjgui-stage805-stage808/stage807}"
SUITE_PACKET="$TMP_DIR/stage807-preview-component-api-state-store-commit-review-history-demo-host-surface-suite.packet"
STAGE806_SUITE_PACKET="${CJGUI_STAGE807_INPUT_PACKET:-${CJGUI_STAGE806_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_REVIEW_TIME_TRAVEL_REHEARSAL_SUITE_PACKET:-/private/tmp/cjgui-stage805-stage808/stage806/stage806-preview-component-api-state-store-commit-review-time-travel-rehearsal-suite.packet}}"
STAGE806_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage807-preview-component-api-state-store-commit-review-history-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage807 preview component api state-store commit review history demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE806_SUITE_PACKET" ]] || ! grep -F "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite_passed=true" "$STAGE806_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE806_TMPDIR="$TMP_DIR/stage806" zsh "$STAGE806_SUITE_SCRIPT" >/dev/null
  STAGE806_SUITE_PACKET="$TMP_DIR/stage806/stage806-preview-component-api-state-store-commit-review-time-travel-rehearsal-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_consumed=true" \
  "review_history_inspection_rows_materialized=true" \
  "time_travel_result_surface_refresh_materialized=true" \
  "timeline_selection_panel_materialized=true" \
  "todo_review_history_preview_surface_materialized=true" \
  "settings_review_history_preview_surface_materialized=true" \
  "ai_generated_settings_review_history_preview_surface_materialized=true" \
  "chat_composer_review_history_preview_surface_materialized=true" \
  "file_browser_review_history_preview_surface_materialized=true" \
  "review_history_demo_host_surface_bound_to_stage806_time_travel_rehearsal=true" \
  "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite_passed=true" \
  "history_replay_receipt_materialized=true" \
  "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_prepared=true"; do
  require_file_fact "$STAGE806_SUITE_PACKET" "$fact"
done

{
  echo "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_suite_version=1"
  echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite_packet=$STAGE806_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage807 preview component api state-store commit review history demo-host surface suite: route_classification=state_store_commit_review_history_demo_host_surface"
echo "cjgui stage807 preview component api state-store commit review history demo-host surface suite: suite_packet_path=$SUITE_PACKET"
