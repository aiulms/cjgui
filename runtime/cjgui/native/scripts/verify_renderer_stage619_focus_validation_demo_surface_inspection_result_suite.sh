#!/usr/bin/env zsh
#
# Focused suite for stage619. It consumes stage618 execution receipts and
# verifies checkable focus/validation demo surface inspection results.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE619_TMPDIR:-/private/tmp/cjgui-stage617-stage620/stage619}"
SUITE_PACKET="$TMP_DIR/stage619-focus-validation-demo-surface-inspection-result-suite.packet"
STAGE618_SUITE_PACKET="${CJGUI_STAGE619_INPUT_PACKET:-${CJGUI_STAGE618_FOCUS_VALIDATION_STATE_RENDER_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage617-stage620/stage618/stage618-focus-validation-state-render-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage619_focus_validation_demo_surface_inspection_result_owner.sh"
OWNER_LOG="$TMP_DIR/stage619-focus-validation-demo-surface-inspection-result-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage619 focus validation demo surface inspection result suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE618_SUITE_PACKET" || ! -f "$STAGE618_SUITE_PACKET" ]]; then
  echo "cjgui stage619 focus validation demo surface inspection result suite: missing stage618 packet; set CJGUI_STAGE619_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage618_focus_validation_state_render_executor_suite_version=1" \
  "shared_focus_validation_state_render_executor_materialized=true" \
  "focus_validation_render_command_refresh_materialized=true" \
  "stage619_focus_validation_demo_surface_inspection_result_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE618_SUITE_PACKET" "$fact"
done

for fact in \
  "stage618_focus_validation_state_render_executor_consumed=true" \
  "shared_focus_validation_demo_surface_inspection_result_materialized=true" \
  "validation_display_surface_refresh_materialized=true" \
  "focus_validation_semantic_diff_receipt_materialized=true" \
  "stage620_shared_focus_validation_input_cycle_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage619_focus_validation_demo_surface_inspection_result_suite_version=1"
  echo "stage618_focus_validation_state_render_executor_suite_packet=$STAGE618_SUITE_PACKET"
  echo "stage619_focus_validation_demo_surface_inspection_result_owner_passed=true"
  echo "stage618_focus_validation_state_render_executor_consumed=true"
  echo "stage617_focus_validation_input_cycle_consumed_transitively=true"
  echo "stage616_focus_validation_runtime_contract_consumed_transitively=true"
  echo "focus_validation_execution_receipts_consumed=true"
  echo "shared_focus_validation_demo_surface_inspection_result_materialized=true"
  echo "validation_display_surface_refresh_materialized=true"
  echo "focus_movement_surface_refresh_materialized=true"
  echo "input_feedback_surface_refresh_materialized=true"
  echo "focus_validation_semantic_diff_receipt_materialized=true"
  echo "todo_focus_validation_demo_surface_inspection_result_materialized=true"
  echo "settings_focus_validation_demo_surface_inspection_result_materialized=true"
  echo "ai_generated_settings_focus_validation_demo_surface_inspection_result_materialized=true"
  echo "chat_composer_focus_validation_demo_surface_inspection_result_materialized=true"
  echo "demo_surface_inspection_bound_to_stage618_receipts=true"
  echo "stage620_shared_focus_validation_input_cycle_runtime_contract_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage619_focus_validation_demo_surface_inspection_result_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage619 focus validation demo surface inspection result suite: route_classification=focus_validation_demo_surface_inspection_ready"
echo "cjgui stage619 focus validation demo surface inspection result suite: suite_packet_path=$SUITE_PACKET"
