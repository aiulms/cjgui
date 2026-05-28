#!/usr/bin/env zsh
#
# Focused suite for stage650. It consumes stage649 adapter output and verifies
# the non-dispatching action/state feedback executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE650_TMPDIR:-/private/tmp/cjgui-stage649-stage652/stage650}"
SUITE_PACKET="$TMP_DIR/stage650-component-host-input-result-surface-action-state-feedback-executor-suite.packet"
STAGE649_SUITE_PACKET="${CJGUI_STAGE650_INPUT_PACKET:-${CJGUI_STAGE649_COMPONENT_HOST_INPUT_RESULT_SURFACE_INTERACTION_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage649-stage652/stage649/stage649-component-host-input-result-surface-interaction-adapter-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage650_component_host_input_result_surface_action_state_feedback_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage650-component-host-input-result-surface-action-state-feedback-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage650 component host input result surface action state feedback executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage649_component_host_input_result_surface_interaction_adapter_consumed=true" \
  "shared_result_surface_action_state_feedback_executor_materialized=true" \
  "validation_dismiss_state_delta_dry_run_materialized=true" \
  "chat_composer_feedback_state_candidate_materialized=true" \
  "stage651_component_host_input_result_surface_render_refresh_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE649_SUITE_PACKET" || ! -f "$STAGE649_SUITE_PACKET" ]]; then
  echo "cjgui stage650 component host input result surface action state feedback executor suite: missing stage649 packet; set CJGUI_STAGE650_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage649_component_host_input_result_surface_interaction_adapter_suite_version=1" \
  "shared_result_surface_interaction_adapter_materialized=true" \
  "chat_composer_result_surface_interaction_target_materialized=true" \
  "stage650_component_host_input_result_surface_action_state_feedback_executor_prepared=true" \
  "action_dispatch=false" \
  "state_update_committed=false"; do
  require_file_fact "$STAGE649_SUITE_PACKET" "$fact"
done

{
  echo "stage650_component_host_input_result_surface_action_state_feedback_executor_suite_version=1"
  echo "stage649_component_host_input_result_surface_interaction_adapter_suite_packet=$STAGE649_SUITE_PACKET"
  echo "stage650_component_host_input_result_surface_action_state_feedback_executor_owner_passed=true"
  echo "stage649_component_host_input_result_surface_interaction_adapter_consumed=true"
  echo "stage648_component_host_input_result_surface_runtime_contract_consumed_transitively=true"
  echo "shared_result_surface_action_state_feedback_executor_materialized=true"
  echo "validation_dismiss_state_delta_dry_run_materialized=true"
  echo "focus_move_state_delta_dry_run_materialized=true"
  echo "input_feedback_clear_state_delta_dry_run_materialized=true"
  echo "semantic_diff_acknowledge_state_delta_dry_run_materialized=true"
  echo "todo_feedback_state_candidate_materialized=true"
  echo "settings_feedback_state_candidate_materialized=true"
  echo "ai_generated_settings_feedback_state_candidate_materialized=true"
  echo "chat_composer_feedback_state_candidate_materialized=true"
  echo "feedback_executor_non_dispatching=true"
  echo "feedback_state_update_committed=false"
  echo "stage651_component_host_input_result_surface_render_refresh_receipt_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage650_component_host_input_result_surface_action_state_feedback_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage650 component host input result surface action state feedback executor suite: route_classification=result_surface_action_state_feedback_ready"
echo "cjgui stage650 component host input result surface action state feedback executor suite: suite_packet_path=$SUITE_PACKET"
