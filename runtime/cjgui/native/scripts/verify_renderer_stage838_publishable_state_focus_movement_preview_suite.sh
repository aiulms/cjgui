#!/usr/bin/env zsh
#
# Focused suite for stage838. It consumes stage837 and records non-dispatching
# focus movement, selection/caret transition, rollback, and explain preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE838_TMPDIR:-/private/tmp/cjgui-stage837-stage840/stage838}"
SUITE_PACKET="$TMP_DIR/stage838-publishable-state-focus-movement-preview-suite.packet"
STAGE837_SUITE_PACKET="${CJGUI_STAGE838_INPUT_PACKET:-${CJGUI_STAGE837_PUBLISHABLE_STATE_FOCUS_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage837-stage840/stage837/stage837-publishable-state-focus-manager-suite.packet}}"
STAGE837_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage838_publishable_state_focus_movement_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage838-publishable-state-focus-movement-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage838 publishable state focus movement preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE837_SUITE_PACKET" ]] || ! grep -F "stage837_publishable_state_focus_manager_suite_passed=true" "$STAGE837_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE837_TMPDIR="$TMP_DIR/stage837" zsh "$STAGE837_SUITE_SCRIPT" >/dev/null
  STAGE837_SUITE_PACKET="$TMP_DIR/stage837/stage837-publishable-state-focus-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage838_publishable_state_focus_movement_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage838_publishable_state_focus_movement_preview_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage837_publishable_state_focus_manager_consumed=true" \
  "stage836_publishable_state_layout_style_runtime_manager_consumed_transitively=true" \
  "owner_local_focus_traversal_manager_input_consumed=true" \
  "owner_local_focus_movement_preview_materialized=true" \
  "selection_caret_transition_preview_materialized=true" \
  "focus_rollback_snapshot_materialized=true" \
  "focus_change_explain_receipt_materialized=true" \
  "focus_movement_bound_to_stage837_focus_manager_input=true" \
  "stage839_publishable_state_focus_demo_surface_prepared=true" \
  "focus_dispatch=false" \
  "focus_mutation=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage837_publishable_state_focus_manager_suite_passed=true" \
  "owner_local_focus_traversal_manager_input_materialized=true" \
  "caret_anchor_candidate_ledger_materialized=true" \
  "stage838_publishable_state_focus_movement_preview_prepared=true"; do
  require_file_fact "$STAGE837_SUITE_PACKET" "$fact"
done

{
  echo "stage838_publishable_state_focus_movement_preview_suite_version=1"
  echo "stage837_suite_packet=$STAGE837_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage839_publishable_state_focus_demo_surface_after_stage838"
  echo "stage838_publishable_state_focus_movement_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage838 publishable state focus movement preview suite: route_classification=focus_movement_preview"
echo "cjgui stage838 publishable state focus movement preview suite: suite_packet_path=$SUITE_PACKET"
