#!/usr/bin/env zsh
#
# Focused suite for stage601. It consumes stage600 host integration evidence
# and emits a shared form result feedback surface input event bridge packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE601_TMPDIR:-/private/tmp/cjgui-stage601-stage604/stage601}"
SUITE_PACKET="$TMP_DIR/stage601-form-result-feedback-surface-input-event-bridge-suite.packet"
STAGE600_SUITE_PACKET="${CJGUI_STAGE601_INPUT_PACKET:-${CJGUI_STAGE600_FORM_RESULT_DEMO_HOST_FEEDBACK_SURFACE_INTEGRATION_SUITE_PACKET:-/private/tmp/cjgui-stage597-stage600/stage600/stage600-form-result-demo-host-feedback-surface-integration-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage601_form_result_feedback_surface_input_event_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage601-form-result-feedback-surface-input-event-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage601 form result feedback surface input event bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage601 form result feedback surface input event bridge suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage600_form_result_demo_host_feedback_surface_integration_consumed=true" \
  "shared_form_result_feedback_surface_input_event_bridge_materialized=true" \
  "feedback_surface_input_route_ledger_materialized=true" \
  "validation_feedback_input_route_materialized=true" \
  "focus_movement_input_route_materialized=true" \
  "input_feedback_display_route_materialized=true" \
  "chat_composer_feedback_surface_input_event_route_materialized=true" \
  "feedback_surface_input_bridge_bound_to_stage600_host_integration=true" \
  "stage602_form_result_feedback_surface_event_normalizer_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE600_SUITE_PACKET" || ! -f "$STAGE600_SUITE_PACKET" ]]; then
  echo "cjgui stage601 form result feedback surface input event bridge suite: missing stage600 packet; set CJGUI_STAGE601_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage600_form_result_demo_host_feedback_surface_integration_suite_version=1" \
  "stage599_form_result_feedback_surface_reducer_consumed=true" \
  "shared_form_result_demo_host_feedback_surface_integration_materialized=true" \
  "shared_form_result_demo_host_feedback_surface_helper_materialized=true" \
  "shared_form_result_demo_host_feedback_execution_contract_materialized=true" \
  "chat_composer_demo_host_feedback_surface_integration_materialized=true" \
  "stage601_form_result_feedback_surface_input_event_bridge_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE600_SUITE_PACKET" "$fact"
done

{
  echo "stage601_form_result_feedback_surface_input_event_bridge_suite_version=1"
  echo "stage600_form_result_demo_host_feedback_surface_integration_suite_packet=$STAGE600_SUITE_PACKET"
  echo "stage601_form_result_feedback_surface_input_event_bridge_owner_passed=true"
  echo "stage600_form_result_demo_host_feedback_surface_integration_consumed=true"
  echo "stage599_form_result_feedback_surface_reducer_consumed_transitively=true"
  echo "shared_form_result_feedback_surface_input_event_bridge_materialized=true"
  echo "feedback_surface_input_route_ledger_materialized=true"
  echo "validation_feedback_input_route_materialized=true"
  echo "focus_movement_input_route_materialized=true"
  echo "input_feedback_display_route_materialized=true"
  echo "todo_feedback_surface_input_event_route_materialized=true"
  echo "settings_feedback_surface_input_event_route_materialized=true"
  echo "ai_generated_settings_feedback_surface_input_event_route_materialized=true"
  echo "chat_composer_feedback_surface_input_event_route_materialized=true"
  echo "feedback_surface_input_bridge_bound_to_stage600_host_integration=true"
  echo "feedback_surface_input_bridge_bound_to_stage599_reducer=true"
  echo "stage602_form_result_feedback_surface_event_normalizer_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
} > "$SUITE_PACKET"

echo "cjgui stage601 form result feedback surface input event bridge suite: route_classification=feedback_surface_input_event_bridge_ready"
echo "cjgui stage601 form result feedback surface input event bridge suite: suite_packet_path=$SUITE_PACKET"
