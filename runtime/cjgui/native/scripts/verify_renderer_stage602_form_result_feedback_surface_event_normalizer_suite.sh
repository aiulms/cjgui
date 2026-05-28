#!/usr/bin/env zsh
#
# Focused suite for stage602. It consumes stage601 input event bridge evidence
# and emits a shared normalized feedback surface event packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE602_TMPDIR:-/private/tmp/cjgui-stage601-stage604/stage602}"
SUITE_PACKET="$TMP_DIR/stage602-form-result-feedback-surface-event-normalizer-suite.packet"
STAGE601_SUITE_PACKET="${CJGUI_STAGE602_INPUT_PACKET:-${CJGUI_STAGE601_FORM_RESULT_FEEDBACK_SURFACE_INPUT_EVENT_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage601-stage604/stage601/stage601-form-result-feedback-surface-input-event-bridge-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage602_form_result_feedback_surface_event_normalizer_owner.sh"
OWNER_LOG="$TMP_DIR/stage602-form-result-feedback-surface-event-normalizer-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage602 form result feedback surface event normalizer suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage602 form result feedback surface event normalizer suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage601_form_result_feedback_surface_input_event_bridge_consumed=true" \
  "shared_form_result_feedback_surface_event_normalizer_materialized=true" \
  "normalized_accepted_feedback_surface_event_materialized=true" \
  "normalized_rejected_validation_feedback_surface_event_materialized=true" \
  "normalized_pending_owner_acceptance_feedback_surface_event_materialized=true" \
  "validation_focus_feedback_event_ledger_materialized=true" \
  "chat_composer_normalized_feedback_surface_event_materialized=true" \
  "event_normalizer_bound_to_stage601_input_event_bridge=true" \
  "stage603_form_result_feedback_surface_event_cycle_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE601_SUITE_PACKET" || ! -f "$STAGE601_SUITE_PACKET" ]]; then
  echo "cjgui stage602 form result feedback surface event normalizer suite: missing stage601 packet; set CJGUI_STAGE602_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage601_form_result_feedback_surface_input_event_bridge_suite_version=1" \
  "stage600_form_result_demo_host_feedback_surface_integration_consumed=true" \
  "feedback_surface_input_route_ledger_materialized=true" \
  "validation_feedback_input_route_materialized=true" \
  "chat_composer_feedback_surface_input_event_route_materialized=true" \
  "stage602_form_result_feedback_surface_event_normalizer_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE601_SUITE_PACKET" "$fact"
done

{
  echo "stage602_form_result_feedback_surface_event_normalizer_suite_version=1"
  echo "stage601_form_result_feedback_surface_input_event_bridge_suite_packet=$STAGE601_SUITE_PACKET"
  echo "stage602_form_result_feedback_surface_event_normalizer_owner_passed=true"
  echo "stage601_form_result_feedback_surface_input_event_bridge_consumed=true"
  echo "stage600_form_result_demo_host_feedback_surface_integration_consumed_transitively=true"
  echo "shared_form_result_feedback_surface_event_normalizer_materialized=true"
  echo "normalized_accepted_feedback_surface_event_materialized=true"
  echo "normalized_rejected_validation_feedback_surface_event_materialized=true"
  echo "normalized_pending_owner_acceptance_feedback_surface_event_materialized=true"
  echo "validation_focus_feedback_event_ledger_materialized=true"
  echo "todo_normalized_feedback_surface_event_materialized=true"
  echo "settings_normalized_feedback_surface_event_materialized=true"
  echo "ai_generated_settings_normalized_feedback_surface_event_materialized=true"
  echo "chat_composer_normalized_feedback_surface_event_materialized=true"
  echo "event_normalizer_bound_to_stage601_input_event_bridge=true"
  echo "event_normalizer_bound_to_stage600_host_integration=true"
  echo "stage603_form_result_feedback_surface_event_cycle_executor_prepared=true"
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

echo "cjgui stage602 form result feedback surface event normalizer suite: route_classification=feedback_surface_event_normalizer_ready"
echo "cjgui stage602 form result feedback surface event normalizer suite: suite_packet_path=$SUITE_PACKET"
