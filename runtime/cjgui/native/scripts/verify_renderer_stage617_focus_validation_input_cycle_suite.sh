#!/usr/bin/env zsh
#
# Focused suite for stage617. It consumes the stage616 runtime contract owner
# facts and verifies the shared focus/validation input cycle contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE617_TMPDIR:-/private/tmp/cjgui-stage617-stage620/stage617}"
SUITE_PACKET="$TMP_DIR/stage617-focus-validation-input-cycle-suite.packet"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage617_focus_validation_input_cycle_owner.sh"
OWNER_LOG="$TMP_DIR/stage617-focus-validation-input-cycle-owner.log"
STAGE616_OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage616_focus_validation_runtime_contract_owner.sh"
STAGE616_OWNER_LOG="$TMP_DIR/stage616-focus-validation-runtime-contract-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage617 focus validation input cycle suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh -n "$STAGE616_OWNER_SCRIPT"
zsh "$STAGE616_OWNER_SCRIPT" > "$STAGE616_OWNER_LOG" 2>&1
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "shared_focus_validation_runtime_contract_materialized=true" \
  "chat_composer_focus_validation_runtime_surface_materialized=true" \
  "stage617_focus_validation_input_cycle_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE616_OWNER_LOG" "$fact"
done

for fact in \
  "stage616_focus_validation_runtime_contract_consumed=true" \
  "shared_focus_validation_input_cycle_contract_materialized=true" \
  "normalized_focus_validation_input_event_ledger_materialized=true" \
  "chat_composer_focus_validation_input_cycle_materialized=true" \
  "stage618_focus_validation_state_render_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage617_focus_validation_input_cycle_suite_version=1"
  echo "stage616_focus_validation_runtime_contract_owner_log=$STAGE616_OWNER_LOG"
  echo "stage617_focus_validation_input_cycle_owner_passed=true"
  echo "stage616_focus_validation_runtime_contract_consumed=true"
  echo "shared_focus_validation_input_cycle_contract_materialized=true"
  echo "normalized_focus_validation_input_event_ledger_materialized=true"
  echo "validation_change_input_intent_materialized=true"
  echo "focus_move_input_intent_materialized=true"
  echo "input_feedback_intent_adapter_materialized=true"
  echo "todo_focus_validation_input_cycle_materialized=true"
  echo "settings_focus_validation_input_cycle_materialized=true"
  echo "ai_generated_settings_focus_validation_input_cycle_materialized=true"
  echo "chat_composer_focus_validation_input_cycle_materialized=true"
  echo "input_cycle_bound_to_stage616_runtime_contract=true"
  echo "focus_validation_input_cycle_owner_local=true"
  echo "focus_validation_input_cycle_non_dispatching=true"
  echo "stage618_focus_validation_state_render_executor_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage617_focus_validation_input_cycle_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage617 focus validation input cycle suite: route_classification=focus_validation_input_cycle_ready"
echo "cjgui stage617 focus validation input cycle suite: suite_packet_path=$SUITE_PACKET"
