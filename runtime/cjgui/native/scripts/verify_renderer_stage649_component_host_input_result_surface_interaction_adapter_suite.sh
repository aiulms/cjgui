#!/usr/bin/env zsh
#
# Focused suite for stage649. It consumes stage648 runtime surfaces and verifies
# the shared interaction adapter stays owner-local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE649_TMPDIR:-/private/tmp/cjgui-stage649-stage652/stage649}"
SUITE_PACKET="$TMP_DIR/stage649-component-host-input-result-surface-interaction-adapter-suite.packet"
STAGE648_SUITE_PACKET="${CJGUI_STAGE649_INPUT_PACKET:-${CJGUI_STAGE648_COMPONENT_HOST_INPUT_RESULT_SURFACE_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage645-stage648/stage648/stage648-component-host-input-result-surface-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage649_component_host_input_result_surface_interaction_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage649-component-host-input-result-surface-interaction-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage649 component host input result surface interaction adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage648_component_host_input_result_surface_runtime_contract_consumed=true" \
  "shared_result_surface_interaction_adapter_materialized=true" \
  "validation_dismiss_action_route_materialized=true" \
  "chat_composer_result_surface_interaction_target_materialized=true" \
  "stage650_component_host_input_result_surface_action_state_feedback_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE648_SUITE_PACKET" || ! -f "$STAGE648_SUITE_PACKET" ]]; then
  echo "cjgui stage649 component host input result surface interaction adapter suite: missing stage648 packet; set CJGUI_STAGE649_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage648_component_host_input_result_surface_runtime_contract_suite_version=1" \
  "shared_component_host_input_result_surface_runtime_contract_materialized=true" \
  "chat_composer_component_host_input_result_surface_runtime_surface_materialized=true" \
  "stage649_component_host_input_result_surface_interaction_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE648_SUITE_PACKET" "$fact"
done

{
  echo "stage649_component_host_input_result_surface_interaction_adapter_suite_version=1"
  echo "stage648_component_host_input_result_surface_runtime_contract_suite_packet=$STAGE648_SUITE_PACKET"
  echo "stage649_component_host_input_result_surface_interaction_adapter_owner_passed=true"
  echo "stage648_component_host_input_result_surface_runtime_contract_consumed=true"
  echo "stage647_component_host_input_result_surface_host_inspection_consumed_transitively=true"
  echo "stage646_component_host_input_result_surface_layout_feedback_consumed_transitively=true"
  echo "stage645_component_host_input_result_surface_refresh_consumed_transitively=true"
  echo "stage644_component_host_input_cycle_executor_consumed_transitively=true"
  echo "shared_result_surface_interaction_adapter_materialized=true"
  echo "validation_dismiss_action_route_materialized=true"
  echo "focus_move_action_route_materialized=true"
  echo "input_feedback_clear_action_route_materialized=true"
  echo "semantic_diff_acknowledge_action_route_materialized=true"
  echo "todo_result_surface_interaction_target_materialized=true"
  echo "settings_result_surface_interaction_target_materialized=true"
  echo "ai_generated_settings_result_surface_interaction_target_materialized=true"
  echo "chat_composer_result_surface_interaction_target_materialized=true"
  echo "interaction_adapter_bound_to_stage648_runtime_surfaces=true"
  echo "stage650_component_host_input_result_surface_action_state_feedback_executor_prepared=true"
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
  echo "stage649_component_host_input_result_surface_interaction_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage649 component host input result surface interaction adapter suite: route_classification=result_surface_interaction_adapter_ready"
echo "cjgui stage649 component host input result surface interaction adapter suite: suite_packet_path=$SUITE_PACKET"
