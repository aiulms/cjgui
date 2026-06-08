#!/usr/bin/env zsh
#
# Focused suite for stage806. It consumes stage805 and records the time-travel rehearsal snapshot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE806_TMPDIR:-/private/tmp/cjgui-stage805-stage808/stage806}"
SUITE_PACKET="$TMP_DIR/stage806-preview-component-api-state-store-commit-review-time-travel-rehearsal-suite.packet"
STAGE805_SUITE_PACKET="${CJGUI_STAGE806_INPUT_PACKET:-${CJGUI_STAGE805_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_REVIEW_HISTORY_SUITE_PACKET:-/private/tmp/cjgui-stage805-stage808/stage805/stage805-preview-component-api-state-store-commit-review-history-suite.packet}}"
STAGE805_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_owner.sh"
OWNER_LOG="$TMP_DIR/stage806-preview-component-api-state-store-commit-review-time-travel-rehearsal-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage806 preview component api state-store commit review time-travel rehearsal suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE805_SUITE_PACKET" ]] || ! grep -F "stage805_preview_component_api_state_store_commit_review_history_suite_passed=true" "$STAGE805_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE805_TMPDIR="$TMP_DIR/stage805" zsh "$STAGE805_SUITE_SCRIPT" >/dev/null
  STAGE805_SUITE_PACKET="$TMP_DIR/stage805/stage805-preview-component-api-state-store-commit-review-history-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage805_preview_component_api_state_store_commit_review_history_consumed=true" \
  "selected_review_history_entry_materialized=true" \
  "rollback_time_travel_snapshot_materialized=true" \
  "pre_commit_state_preview_materialized=true" \
  "post_review_state_preview_materialized=true" \
  "history_replay_receipt_materialized=true" \
  "time_travel_rehearsal_non_committing=true" \
  "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_prepared=true" \
  "new_public_surface_added=false" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage805_preview_component_api_state_store_commit_review_history_suite_passed=true" \
  "commit_review_history_ledger_materialized=true" \
  "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_prepared=true"; do
  require_file_fact "$STAGE805_SUITE_PACKET" "$fact"
done

{
  echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite_version=1"
  echo "stage805_preview_component_api_state_store_commit_review_history_suite_packet=$STAGE805_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage806 preview component api state-store commit review time-travel rehearsal suite: route_classification=state_store_commit_review_time_travel_rehearsal"
echo "cjgui stage806 preview component api state-store commit review time-travel rehearsal suite: suite_packet_path=$SUITE_PACKET"
