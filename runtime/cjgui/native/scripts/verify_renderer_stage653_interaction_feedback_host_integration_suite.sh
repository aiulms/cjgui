#!/usr/bin/env zsh
#
# Focused suite for stage653. It consumes stage652 runtime-surface packet facts
# and verifies the shared interaction feedback host integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE653_TMPDIR:-/private/tmp/cjgui-stage653-stage656/stage653}"
SUITE_PACKET="$TMP_DIR/stage653-interaction-feedback-host-integration-suite.packet"
STAGE652_SUITE_PACKET="${CJGUI_STAGE653_INPUT_PACKET:-${CJGUI_STAGE652_INTERACTION_FEEDBACK_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage649-stage652/stage652/stage652-component-host-input-result-surface-interaction-feedback-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage653_interaction_feedback_host_integration_owner.sh"
OWNER_LOG="$TMP_DIR/stage653-interaction-feedback-host-integration-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage653 interaction feedback host integration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage652_interaction_feedback_runtime_contract_consumed=true" \
  "shared_interaction_feedback_host_integration_slots_materialized=true" \
  "chat_composer_interaction_feedback_host_integration_materialized=true" \
  "stage654_interaction_feedback_host_frame_assembly_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE652_SUITE_PACKET" || ! -f "$STAGE652_SUITE_PACKET" ]]; then
  echo "cjgui stage653 interaction feedback host integration suite: missing stage652 packet; set CJGUI_STAGE653_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage652_component_host_input_result_surface_interaction_feedback_runtime_contract_suite_version=1" \
  "shared_interaction_feedback_runtime_contract_materialized=true" \
  "chat_composer_interaction_feedback_runtime_surface_materialized=true" \
  "stage653_component_host_input_result_surface_interaction_host_integration_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE652_SUITE_PACKET" "$fact"
done

{
  echo "stage653_interaction_feedback_host_integration_suite_version=1"
  echo "stage652_interaction_feedback_runtime_contract_suite_packet=$STAGE652_SUITE_PACKET"
  echo "stage653_interaction_feedback_host_integration_owner_passed=true"
  echo "stage652_interaction_feedback_runtime_contract_consumed=true"
  echo "interaction_feedback_runtime_surfaces_consumed=true"
  echo "shared_interaction_feedback_host_integration_slots_materialized=true"
  echo "validation_dismiss_host_slot_materialized=true"
  echo "focus_movement_host_slot_materialized=true"
  echo "input_feedback_clear_host_slot_materialized=true"
  echo "semantic_diff_acknowledge_host_slot_materialized=true"
  echo "todo_interaction_feedback_host_integration_materialized=true"
  echo "settings_interaction_feedback_host_integration_materialized=true"
  echo "ai_generated_settings_interaction_feedback_host_integration_materialized=true"
  echo "chat_composer_interaction_feedback_host_integration_materialized=true"
  echo "host_integration_bound_to_stage652_runtime_contract=true"
  echo "stage654_interaction_feedback_host_frame_assembly_prepared=true"
  echo "host_mutation=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage654_interaction_feedback_host_frame_assembly_after_stage653"
  echo "stage653_interaction_feedback_host_integration_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage653 interaction feedback host integration suite: route_classification=host_integration_ready"
echo "cjgui stage653 interaction feedback host integration suite: suite_packet_path=$SUITE_PACKET"
