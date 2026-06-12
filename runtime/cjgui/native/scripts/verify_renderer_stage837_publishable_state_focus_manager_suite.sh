#!/usr/bin/env zsh
#
# Focused suite for stage837. It consumes stage836 and records owner-local
# focus traversal manager input for publishable state slots.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE837_TMPDIR:-/private/tmp/cjgui-stage837-stage840/stage837}"
SUITE_PACKET="$TMP_DIR/stage837-publishable-state-focus-manager-suite.packet"
STAGE836_SUITE_PACKET="${CJGUI_STAGE837_INPUT_PACKET:-${CJGUI_STAGE836_PUBLISHABLE_STATE_LAYOUT_STYLE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage833-stage836/stage836/stage836-publishable-state-layout-style-runtime-manager-suite.packet}}"
STAGE836_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage836_publishable_state_layout_style_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage837-publishable-state-focus-manager-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage837 publishable state focus manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE836_SUITE_PACKET" ]] || ! grep -F "stage836_publishable_state_layout_style_runtime_manager_suite_passed=true" "$STAGE836_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE836_TMPDIR="$TMP_DIR/stage836" zsh "$STAGE836_SUITE_SCRIPT" >/dev/null
  STAGE836_SUITE_PACKET="$TMP_DIR/stage836/stage836-publishable-state-layout-style-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage836_publishable_state_layout_style_runtime_manager_consumed=true" \
  "stage835_publishable_state_layout_style_demo_surface_consumed_transitively=true" \
  "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true" \
  "owner_local_focus_traversal_manager_input_materialized=true" \
  "focus_scope_candidate_ledger_materialized=true" \
  "focusable_slot_order_ledger_materialized=true" \
  "caret_anchor_candidate_ledger_materialized=true" \
  "focus_manager_bound_to_stage834_measurement_plan=true" \
  "focus_manager_bound_to_stage836_runtime_manager=true" \
  "stage838_publishable_state_focus_movement_preview_prepared=true" \
  "focus_manager_enabled=false" \
  "focus_mutation=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage836_publishable_state_layout_style_runtime_manager_suite_passed=true" \
  "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true" \
  "layout_style_runtime_manager_bound_to_stage834_measurement_plan=true" \
  "stage837_publishable_state_focus_manager_after_stage836_prepared=true"; do
  require_file_fact "$STAGE836_SUITE_PACKET" "$fact"
done

{
  echo "stage837_publishable_state_focus_manager_suite_version=1"
  echo "stage836_suite_packet=$STAGE836_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage838_publishable_state_focus_movement_preview_after_stage837"
  echo "stage837_publishable_state_focus_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage837 publishable state focus manager suite: route_classification=focus_manager_input"
echo "cjgui stage837 publishable state focus manager suite: suite_packet_path=$SUITE_PACKET"
