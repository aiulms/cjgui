#!/usr/bin/env zsh
#
# Focused suite for stage642. It consumes stage641 adapter routes and verifies
# the shared component host input event queue.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE642_TMPDIR:-/private/tmp/cjgui-stage641-stage644/stage642}"
SUITE_PACKET="$TMP_DIR/stage642-component-host-input-event-queue-suite.packet"
STAGE641_SUITE_PACKET="${CJGUI_STAGE642_INPUT_PACKET:-${CJGUI_STAGE641_RESULT_SURFACE_HOST_INPUT_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage641-stage644/stage641/stage641-result-surface-host-input-adapter-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage642_component_host_input_event_queue_owner.sh"
OWNER_LOG="$TMP_DIR/stage642-component-host-input-event-queue-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage642 component host input event queue suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage641_result_surface_host_input_adapter_consumed=true" \
  "shared_component_host_input_event_queue_materialized=true" \
  "normalized_validation_ack_host_input_event_materialized=true" \
  "chat_composer_component_host_input_event_queue_materialized=true" \
  "stage643_component_host_input_cycle_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE641_SUITE_PACKET" || ! -f "$STAGE641_SUITE_PACKET" ]]; then
  echo "cjgui stage642 component host input event queue suite: missing stage641 packet; set CJGUI_STAGE642_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage641_result_surface_host_input_adapter_suite_version=1" \
  "shared_result_surface_host_input_adapter_materialized=true" \
  "chat_composer_result_surface_host_input_adapter_materialized=true" \
  "stage642_component_host_input_event_queue_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE641_SUITE_PACKET" "$fact"
done

{
  echo "stage642_component_host_input_event_queue_suite_version=1"
  echo "stage641_result_surface_host_input_adapter_suite_packet=$STAGE641_SUITE_PACKET"
  echo "stage642_component_host_input_event_queue_owner_passed=true"
  echo "stage641_result_surface_host_input_adapter_consumed=true"
  echo "stage640_result_surface_host_runtime_contract_consumed_transitively=true"
  echo "shared_component_host_input_event_queue_materialized=true"
  echo "normalized_validation_ack_host_input_event_materialized=true"
  echo "normalized_focus_move_host_input_event_materialized=true"
  echo "normalized_input_feedback_dismiss_host_input_event_materialized=true"
  echo "normalized_semantic_refresh_host_input_event_materialized=true"
  echo "component_host_input_event_queue_ledger_materialized=true"
  echo "todo_component_host_input_event_queue_materialized=true"
  echo "settings_component_host_input_event_queue_materialized=true"
  echo "ai_generated_settings_component_host_input_event_queue_materialized=true"
  echo "chat_composer_component_host_input_event_queue_materialized=true"
  echo "component_host_input_event_queue_bound_to_stage641_adapter=true"
  echo "component_host_input_event_queue_owner_local=true"
  echo "component_host_input_event_queue_non_executing=true"
  echo "stage643_component_host_input_cycle_receipt_prepared=true"
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
  echo "next_route=stage643_component_host_input_cycle_receipt_after_stage642"
  echo "stage642_component_host_input_event_queue_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage642 component host input event queue suite: route_classification=component_host_input_event_queue_ready"
echo "cjgui stage642 component host input event queue suite: suite_packet_path=$SUITE_PACKET"
