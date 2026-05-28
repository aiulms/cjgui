#!/usr/bin/env zsh
#
# Focused suite for stage625. It consumes stage624 demo-host runtime contract
# and verifies the shared host input adapter packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE625_TMPDIR:-/private/tmp/cjgui-stage625-stage628/stage625}"
SUITE_PACKET="$TMP_DIR/stage625-focus-validation-host-input-adapter-suite.packet"
STAGE624_SUITE_PACKET="${CJGUI_STAGE625_INPUT_PACKET:-${CJGUI_STAGE624_SHARED_FOCUS_VALIDATION_DEMO_HOST_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage621-stage624/stage624/stage624-shared-focus-validation-demo-host-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage625_focus_validation_host_input_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage625-focus-validation-host-input-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage625 focus validation host input adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE624_SUITE_PACKET" || ! -f "$STAGE624_SUITE_PACKET" ]]; then
  echo "cjgui stage625 focus validation host input adapter suite: missing stage624 packet; set CJGUI_STAGE625_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage624_shared_focus_validation_demo_host_runtime_contract_suite_version=1" \
  "shared_focus_validation_demo_host_runtime_contract_materialized=true" \
  "cycle_order_input_action_state_render_surface_host_frame_receipt_materialized=true" \
  "stage625_component_runtime_focus_validation_host_input_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE624_SUITE_PACKET" "$fact"
done

for fact in \
  "stage624_shared_focus_validation_demo_host_runtime_contract_consumed=true" \
  "shared_focus_validation_host_input_adapter_materialized=true" \
  "host_frame_input_binding_ledger_materialized=true" \
  "chat_composer_focus_validation_host_input_adapter_materialized=true" \
  "stage626_component_runtime_focus_validation_host_input_event_normalizer_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage625_focus_validation_host_input_adapter_suite_version=1"
  echo "stage624_shared_focus_validation_demo_host_runtime_contract_suite_packet=$STAGE624_SUITE_PACKET"
  echo "stage625_focus_validation_host_input_adapter_owner_passed=true"
  echo "stage624_shared_focus_validation_demo_host_runtime_contract_consumed=true"
  echo "stage623_focus_validation_host_interaction_receipt_consumed_transitively=true"
  echo "stage622_focus_validation_host_frame_assembly_consumed_transitively=true"
  echo "stage621_focus_validation_host_integration_consumed_transitively=true"
  echo "shared_focus_validation_host_input_adapter_materialized=true"
  echo "host_frame_input_binding_ledger_materialized=true"
  echo "validation_display_host_input_route_materialized=true"
  echo "focus_handoff_host_input_route_materialized=true"
  echo "input_feedback_host_input_route_materialized=true"
  echo "semantic_diff_host_input_route_materialized=true"
  echo "todo_focus_validation_host_input_adapter_materialized=true"
  echo "settings_focus_validation_host_input_adapter_materialized=true"
  echo "ai_generated_settings_focus_validation_host_input_adapter_materialized=true"
  echo "chat_composer_focus_validation_host_input_adapter_materialized=true"
  echo "host_input_adapter_bound_to_stage624_runtime_contract=true"
  echo "host_input_adapter_bound_to_stage623_interaction_receipt=true"
  echo "host_input_adapter_owner_local=true"
  echo "host_input_adapter_non_executing=true"
  echo "stage626_component_runtime_focus_validation_host_input_event_normalizer_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage625_focus_validation_host_input_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage625 focus validation host input adapter suite: route_classification=focus_validation_host_input_adapter_ready"
echo "cjgui stage625 focus validation host input adapter suite: suite_packet_path=$SUITE_PACKET"
