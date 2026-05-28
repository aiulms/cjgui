#!/usr/bin/env zsh
#
# Focused suite for stage651. It consumes stage650 feedback deltas and verifies
# RenderCommand/result-surface refresh receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE651_TMPDIR:-/private/tmp/cjgui-stage649-stage652/stage651}"
SUITE_PACKET="$TMP_DIR/stage651-component-host-input-result-surface-render-refresh-receipt-suite.packet"
STAGE650_SUITE_PACKET="${CJGUI_STAGE651_INPUT_PACKET:-${CJGUI_STAGE650_COMPONENT_HOST_INPUT_RESULT_SURFACE_ACTION_STATE_FEEDBACK_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage649-stage652/stage650/stage650-component-host-input-result-surface-action-state-feedback-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage651_component_host_input_result_surface_render_refresh_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage651-component-host-input-result-surface-render-refresh-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage651 component host input result surface render refresh receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage650_component_host_input_result_surface_action_state_feedback_executor_consumed=true" \
  "shared_result_surface_render_refresh_receipt_materialized=true" \
  "validation_display_render_refresh_receipt_materialized=true" \
  "chat_composer_result_surface_render_refresh_receipt_materialized=true" \
  "stage652_component_host_input_result_surface_interaction_feedback_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE650_SUITE_PACKET" || ! -f "$STAGE650_SUITE_PACKET" ]]; then
  echo "cjgui stage651 component host input result surface render refresh receipt suite: missing stage650 packet; set CJGUI_STAGE651_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage650_component_host_input_result_surface_action_state_feedback_executor_suite_version=1" \
  "shared_result_surface_action_state_feedback_executor_materialized=true" \
  "chat_composer_feedback_state_candidate_materialized=true" \
  "stage651_component_host_input_result_surface_render_refresh_receipt_prepared=true" \
  "action_dispatch=false" \
  "state_update_committed=false"; do
  require_file_fact "$STAGE650_SUITE_PACKET" "$fact"
done

{
  echo "stage651_component_host_input_result_surface_render_refresh_receipt_suite_version=1"
  echo "stage650_component_host_input_result_surface_action_state_feedback_executor_suite_packet=$STAGE650_SUITE_PACKET"
  echo "stage651_component_host_input_result_surface_render_refresh_receipt_owner_passed=true"
  echo "stage650_component_host_input_result_surface_action_state_feedback_executor_consumed=true"
  echo "stage649_component_host_input_result_surface_interaction_adapter_consumed_transitively=true"
  echo "stage648_component_host_input_result_surface_runtime_contract_consumed_transitively=true"
  echo "shared_result_surface_render_refresh_receipt_materialized=true"
  echo "validation_display_render_refresh_receipt_materialized=true"
  echo "focus_movement_render_refresh_receipt_materialized=true"
  echo "input_feedback_render_refresh_receipt_materialized=true"
  echo "semantic_diff_render_refresh_receipt_materialized=true"
  echo "todo_result_surface_render_refresh_receipt_materialized=true"
  echo "settings_result_surface_render_refresh_receipt_materialized=true"
  echo "ai_generated_settings_result_surface_render_refresh_receipt_materialized=true"
  echo "chat_composer_result_surface_render_refresh_receipt_materialized=true"
  echo "render_refresh_receipt_bound_to_stage650_feedback_deltas=true"
  echo "stage652_component_host_input_result_surface_interaction_feedback_runtime_contract_prepared=true"
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
  echo "stage651_component_host_input_result_surface_render_refresh_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage651 component host input result surface render refresh receipt suite: route_classification=result_surface_render_refresh_receipt_ready"
echo "cjgui stage651 component host input result surface render refresh receipt suite: suite_packet_path=$SUITE_PACKET"
