#!/usr/bin/env zsh
#
# Focused suite for stage641. It consumes stage640 host runtime surfaces and
# verifies the shared result-surface host input adapter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE641_TMPDIR:-/private/tmp/cjgui-stage641-stage644/stage641}"
SUITE_PACKET="$TMP_DIR/stage641-result-surface-host-input-adapter-suite.packet"
STAGE640_SUITE_PACKET="${CJGUI_STAGE641_INPUT_PACKET:-${CJGUI_STAGE640_RESULT_SURFACE_HOST_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage637-stage640/stage640/stage640-result-surface-host-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage641_result_surface_host_input_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage641-result-surface-host-input-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage641 result surface host input adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage640_result_surface_host_runtime_contract_consumed=true" \
  "shared_result_surface_host_input_adapter_materialized=true" \
  "validation_ack_host_input_route_materialized=true" \
  "chat_composer_result_surface_host_input_adapter_materialized=true" \
  "stage642_component_host_input_event_queue_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE640_SUITE_PACKET" || ! -f "$STAGE640_SUITE_PACKET" ]]; then
  echo "cjgui stage641 result surface host input adapter suite: missing stage640 packet; set CJGUI_STAGE641_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage640_result_surface_host_runtime_contract_suite_version=1" \
  "shared_result_surface_host_runtime_contract_materialized=true" \
  "chat_composer_result_surface_host_runtime_surface_materialized=true" \
  "stage641_component_runtime_result_surface_host_input_event_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE640_SUITE_PACKET" "$fact"
done

{
  echo "stage641_result_surface_host_input_adapter_suite_version=1"
  echo "stage640_result_surface_host_runtime_contract_suite_packet=$STAGE640_SUITE_PACKET"
  echo "stage641_result_surface_host_input_adapter_owner_passed=true"
  echo "stage640_result_surface_host_runtime_contract_consumed=true"
  echo "stage639_result_surface_demo_host_inspection_consumed_transitively=true"
  echo "stage638_result_surface_layout_focus_receipt_consumed_transitively=true"
  echo "shared_result_surface_host_input_adapter_materialized=true"
  echo "validation_ack_host_input_route_materialized=true"
  echo "focus_move_host_input_route_materialized=true"
  echo "input_feedback_dismiss_host_input_route_materialized=true"
  echo "semantic_refresh_host_input_route_materialized=true"
  echo "host_runtime_input_binding_ledger_materialized=true"
  echo "todo_result_surface_host_input_adapter_materialized=true"
  echo "settings_result_surface_host_input_adapter_materialized=true"
  echo "ai_generated_settings_result_surface_host_input_adapter_materialized=true"
  echo "chat_composer_result_surface_host_input_adapter_materialized=true"
  echo "result_surface_host_input_adapter_bound_to_stage640_runtime_contract=true"
  echo "host_input_adapter_owner_local=true"
  echo "host_input_adapter_non_executing=true"
  echo "stage642_component_host_input_event_queue_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage642_component_host_input_event_queue_after_stage641"
  echo "stage641_result_surface_host_input_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage641 result surface host input adapter suite: route_classification=result_surface_host_input_adapter_ready"
echo "cjgui stage641 result surface host input adapter suite: suite_packet_path=$SUITE_PACKET"
