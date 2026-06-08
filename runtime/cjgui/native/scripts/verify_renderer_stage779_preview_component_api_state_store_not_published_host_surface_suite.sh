#!/usr/bin/env zsh
#
# Focused suite for stage779. It consumes stage778 and records a not-published
# host surface for preview component API state-store commit evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE779_TMPDIR:-/private/tmp/cjgui-stage777-stage780/stage779}"
SUITE_PACKET="$TMP_DIR/stage779-preview-component-api-state-store-not-published-host-surface-suite.packet"
STAGE778_SUITE_PACKET="${CJGUI_STAGE779_INPUT_PACKET:-${CJGUI_STAGE778_PREVIEW_COMPONENT_API_STATE_STORE_ROLLBACK_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage777-stage780/stage778/stage778-preview-component-api-state-store-rollback-snapshot-suite.packet}}"
STAGE778_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage778_preview_component_api_state_store_rollback_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage779_preview_component_api_state_store_not_published_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage779-preview-component-api-state-store-not-published-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage779 preview component api state-store not-published host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE778_SUITE_PACKET" ]] || ! grep -F "stage778_preview_component_api_state_store_rollback_snapshot_suite_passed=true" "$STAGE778_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE778_TMPDIR="$TMP_DIR/stage778" zsh "$STAGE778_SUITE_SCRIPT" >/dev/null
  STAGE778_SUITE_PACKET="$TMP_DIR/stage778/stage778-preview-component-api-state-store-rollback-snapshot-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage778_preview_component_api_state_store_rollback_snapshot_consumed=true" \
  "state_store_not_published_receipt_materialized=true" \
  "state_store_commit_host_inspection_rows_materialized=true" \
  "state_store_commit_result_surface_refresh_materialized=true" \
  "state_store_semantic_diff_preview_materialized=true" \
  "chat_composer_preview_component_api_state_store_not_published_host_surface_materialized=true" \
  "state_store_not_published_host_surface_bound_to_stage778_rollback_snapshot=true" \
  "stage780_preview_component_api_state_store_commit_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage778_preview_component_api_state_store_rollback_snapshot_suite_passed=true" \
  "state_store_rollback_base_snapshot_materialized=true" \
  "state_store_rollback_snapshot_bound_to_stage777_boundary=true"; do
  require_file_fact "$STAGE778_SUITE_PACKET" "$fact"
done

{
  echo "stage779_preview_component_api_state_store_not_published_host_surface_suite_version=1"
  echo "stage778_preview_component_api_state_store_rollback_snapshot_suite_packet=$STAGE778_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage780_preview_component_api_state_store_commit_runtime_manager_after_stage779"
  echo "stage779_preview_component_api_state_store_not_published_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage779 preview component api state-store not-published host surface suite: route_classification=preview_api_state_store_not_published_host_surface"
echo "cjgui stage779 preview component api state-store not-published host surface suite: suite_packet_path=$SUITE_PACKET"
