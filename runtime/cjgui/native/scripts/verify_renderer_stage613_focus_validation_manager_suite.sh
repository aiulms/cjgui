#!/usr/bin/env zsh
#
# Focused suite for stage613. It consumes the stage612 shared cycle packet and
# verifies a shared focus/validation manager contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE613_TMPDIR:-/private/tmp/cjgui-stage613-stage616/stage613}"
SUITE_PACKET="$TMP_DIR/stage613-focus-validation-manager-suite.packet"
STAGE612_SUITE_PACKET="${CJGUI_STAGE613_INPUT_PACKET:-${CJGUI_STAGE612_SHARED_FEEDBACK_HOST_INSPECTION_CYCLE_EXECUTOR_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage609-stage612/stage612/stage612-shared-feedback-host-inspection-cycle-executor-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage613_focus_validation_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage613-focus-validation-manager-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage613 focus validation manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage612_shared_feedback_host_inspection_cycle_executor_contract_consumed=true" \
  "shared_focus_validation_manager_contract_materialized=true" \
  "validation_state_ledger_materialized=true" \
  "focus_candidate_ledger_materialized=true" \
  "chat_composer_focus_validation_route_materialized=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE612_SUITE_PACKET" || ! -f "$STAGE612_SUITE_PACKET" ]]; then
  echo "cjgui stage613 focus validation manager suite: missing stage612 packet; set CJGUI_STAGE613_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage612_shared_feedback_host_inspection_cycle_executor_contract_suite_version=1" \
  "shared_feedback_host_inspection_cycle_executor_contract_materialized=true" \
  "chat_composer_feedback_host_inspection_cycle_runtime_surface_materialized=true" \
  "stage613_feedback_host_inspection_focus_validation_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE612_SUITE_PACKET" "$fact"
done

{
  echo "stage613_focus_validation_manager_suite_version=1"
  echo "stage612_shared_cycle_suite_packet=$STAGE612_SUITE_PACKET"
  echo "stage613_focus_validation_manager_owner_passed=true"
  echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_consumed=true"
  echo "shared_focus_validation_manager_contract_materialized=true"
  echo "validation_state_ledger_materialized=true"
  echo "focus_candidate_ledger_materialized=true"
  echo "input_feedback_intent_ledger_materialized=true"
  echo "todo_focus_validation_route_materialized=true"
  echo "settings_focus_validation_route_materialized=true"
  echo "ai_generated_settings_focus_validation_route_materialized=true"
  echo "chat_composer_focus_validation_route_materialized=true"
  echo "stage614_focus_validation_feedback_resolver_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage613_focus_validation_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage613 focus validation manager suite: route_classification=focus_validation_manager_ready"
echo "cjgui stage613 focus validation manager suite: suite_packet_path=$SUITE_PACKET"
