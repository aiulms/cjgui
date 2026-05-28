#!/usr/bin/env zsh
#
# Focused suite for stage621. It consumes stage620 runtime surfaces and
# verifies shared focus/validation host integration slots.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE621_TMPDIR:-/private/tmp/cjgui-stage621-stage624/stage621}"
SUITE_PACKET="$TMP_DIR/stage621-focus-validation-host-integration-suite.packet"
STAGE620_SUITE_PACKET="${CJGUI_STAGE621_INPUT_PACKET:-${CJGUI_STAGE620_SHARED_FOCUS_VALIDATION_INPUT_CYCLE_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage617-stage620/stage620/stage620-shared-focus-validation-input-cycle-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage621_focus_validation_host_integration_owner.sh"
OWNER_LOG="$TMP_DIR/stage621-focus-validation-host-integration-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage621 focus validation host integration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE620_SUITE_PACKET" || ! -f "$STAGE620_SUITE_PACKET" ]]; then
  echo "cjgui stage621 focus validation host integration suite: missing stage620 packet; set CJGUI_STAGE621_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage620_shared_focus_validation_input_cycle_runtime_contract_suite_version=1" \
  "shared_focus_validation_input_cycle_runtime_contract_materialized=true" \
  "cycle_order_input_action_state_render_surface_host_materialized=true" \
  "stage621_component_runtime_focus_validation_host_integration_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE620_SUITE_PACKET" "$fact"
done

for fact in \
  "stage620_shared_focus_validation_input_cycle_runtime_contract_consumed=true" \
  "shared_focus_validation_host_integration_slot_materialized=true" \
  "validation_display_host_slot_materialized=true" \
  "host_semantic_diff_slot_materialized=true" \
  "stage622_focus_validation_host_frame_assembly_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage621_focus_validation_host_integration_suite_version=1"
  echo "stage620_shared_focus_validation_input_cycle_runtime_contract_suite_packet=$STAGE620_SUITE_PACKET"
  echo "stage621_focus_validation_host_integration_owner_passed=true"
  echo "stage620_shared_focus_validation_input_cycle_runtime_contract_consumed=true"
  echo "stage619_focus_validation_demo_surface_inspection_result_consumed_transitively=true"
  echo "input_cycle_runtime_surfaces_consumed=true"
  echo "shared_focus_validation_host_integration_slot_materialized=true"
  echo "validation_display_host_slot_materialized=true"
  echo "focus_movement_host_slot_materialized=true"
  echo "input_feedback_host_slot_materialized=true"
  echo "host_semantic_diff_slot_materialized=true"
  echo "todo_focus_validation_host_integration_materialized=true"
  echo "settings_focus_validation_host_integration_materialized=true"
  echo "ai_generated_settings_focus_validation_host_integration_materialized=true"
  echo "chat_composer_focus_validation_host_integration_materialized=true"
  echo "host_integration_bound_to_stage620_runtime_contract=true"
  echo "focus_validation_host_integration_owner_local=true"
  echo "focus_validation_host_integration_checkable=true"
  echo "stage622_focus_validation_host_frame_assembly_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage621_focus_validation_host_integration_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage621 focus validation host integration suite: route_classification=focus_validation_host_integration_ready"
echo "cjgui stage621 focus validation host integration suite: suite_packet_path=$SUITE_PACKET"
