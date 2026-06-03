#!/usr/bin/env zsh
#
# Focused suite for stage735. It consumes stage734 and verifies the checkable
# commit host inspection UI surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE735_TMPDIR:-/private/tmp/cjgui-stage733-stage736/stage735}"
SUITE_PACKET="$TMP_DIR/stage735-component-visual-state-store-commit-host-inspection-ui-suite.packet"
STAGE734_SUITE_PACKET="${CJGUI_STAGE735_INPUT_PACKET:-${CJGUI_STAGE734_COMPONENT_VISUAL_STATE_STORE_COMMIT_ROLLBACK_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage733-stage736/stage734/stage734-component-visual-state-store-commit-rollback-snapshot-suite.packet}}"
STAGE734_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage734_component_visual_state_store_commit_rollback_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage735_component_visual_state_store_commit_host_inspection_ui_owner.sh"
OWNER_LOG="$TMP_DIR/stage735-component-visual-state-store-commit-host-inspection-ui-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage735 component visual state store commit host inspection ui suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE734_SUITE_PACKET" ]] || ! grep -F "stage734_component_visual_state_store_commit_rollback_snapshot_suite_passed=true" "$STAGE734_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE734_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage734_component_visual_state_store_commit_rollback_snapshot_consumed=true" \
  "commit_demo_host_inspection_ui_surface_materialized=true" \
  "commit_slot_diff_row_model_materialized=true" \
  "commit_validation_message_row_materialized=true" \
  "commit_render_command_refresh_receipt_materialized=true" \
  "commit_host_inspection_probe_input_contract_materialized=true" \
  "stage736_component_state_store_commit_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage734_component_visual_state_store_commit_rollback_snapshot_suite_version=1" \
  "commit_rollback_base_snapshot_materialized=true" \
  "commit_conflict_classifier_materialized=true" \
  "stage735_component_visual_state_store_commit_host_inspection_ui_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE734_SUITE_PACKET" "$fact"
done

{
  echo "stage735_component_visual_state_store_commit_host_inspection_ui_suite_version=1"
  echo "stage734_component_visual_state_store_commit_rollback_snapshot_suite_packet=$STAGE734_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage736_component_state_store_commit_runtime_manager_after_stage735"
  echo "stage735_component_visual_state_store_commit_host_inspection_ui_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage735 component visual state store commit host inspection ui suite: route_classification=component_visual_state_store_commit_host_inspection_ui_ready"
echo "cjgui stage735 component visual state store commit host inspection ui suite: suite_packet_path=$SUITE_PACKET"
