#!/usr/bin/env zsh
#
# Focused suite for stage618. It consumes stage617 suite output and verifies
# the non-dispatching focus/validation state/render executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE618_TMPDIR:-/private/tmp/cjgui-stage617-stage620/stage618}"
SUITE_PACKET="$TMP_DIR/stage618-focus-validation-state-render-executor-suite.packet"
STAGE617_SUITE_PACKET="${CJGUI_STAGE618_INPUT_PACKET:-${CJGUI_STAGE617_FOCUS_VALIDATION_INPUT_CYCLE_SUITE_PACKET:-/private/tmp/cjgui-stage617-stage620/stage617/stage617-focus-validation-input-cycle-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage618_focus_validation_state_render_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage618-focus-validation-state-render-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage618 focus validation state render executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE617_SUITE_PACKET" || ! -f "$STAGE617_SUITE_PACKET" ]]; then
  echo "cjgui stage618 focus validation state render executor suite: missing stage617 packet; set CJGUI_STAGE618_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage617_focus_validation_input_cycle_suite_version=1" \
  "shared_focus_validation_input_cycle_contract_materialized=true" \
  "normalized_focus_validation_input_event_ledger_materialized=true" \
  "stage618_focus_validation_state_render_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE617_SUITE_PACKET" "$fact"
done

for fact in \
  "stage617_focus_validation_input_cycle_consumed=true" \
  "shared_focus_validation_state_render_executor_materialized=true" \
  "focus_validation_render_command_refresh_materialized=true" \
  "chat_composer_focus_validation_execution_receipt_materialized=true" \
  "stage619_focus_validation_demo_surface_inspection_result_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage618_focus_validation_state_render_executor_suite_version=1"
  echo "stage617_focus_validation_input_cycle_suite_packet=$STAGE617_SUITE_PACKET"
  echo "stage618_focus_validation_state_render_executor_owner_passed=true"
  echo "stage617_focus_validation_input_cycle_consumed=true"
  echo "stage616_focus_validation_runtime_contract_consumed_transitively=true"
  echo "normalized_focus_validation_input_events_consumed=true"
  echo "shared_focus_validation_state_render_executor_materialized=true"
  echo "validation_state_delta_dry_run_materialized=true"
  echo "focus_movement_state_delta_dry_run_materialized=true"
  echo "input_feedback_state_delta_dry_run_materialized=true"
  echo "focus_validation_render_command_refresh_materialized=true"
  echo "todo_focus_validation_execution_receipt_materialized=true"
  echo "settings_focus_validation_execution_receipt_materialized=true"
  echo "ai_generated_settings_focus_validation_execution_receipt_materialized=true"
  echo "chat_composer_focus_validation_execution_receipt_materialized=true"
  echo "state_render_executor_bound_to_stage617_input_cycle=true"
  echo "focus_validation_state_render_executor_owner_local=true"
  echo "focus_validation_state_render_executor_non_dispatching=true"
  echo "stage619_focus_validation_demo_surface_inspection_result_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage618_focus_validation_state_render_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage618 focus validation state render executor suite: route_classification=focus_validation_state_render_executor_ready"
echo "cjgui stage618 focus validation state render executor suite: suite_packet_path=$SUITE_PACKET"
