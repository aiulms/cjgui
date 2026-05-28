#!/usr/bin/env zsh
#
# Focused suite for stage666. It consumes the stage665 demo-host surface and
# verifies host inspection receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE666_TMPDIR:-/private/tmp/cjgui-stage665-stage668/stage666}"
SUITE_PACKET="$TMP_DIR/stage666-component-feedback-input-host-inspection-receipt-suite.packet"
STAGE665_SUITE_PACKET="${CJGUI_STAGE666_INPUT_PACKET:-${CJGUI_STAGE665_COMPONENT_FEEDBACK_INPUT_DEMO_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage665-stage668/stage665/stage665-component-feedback-input-demo-host-surface-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage666_component_feedback_input_host_inspection_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage666-component-feedback-input-host-inspection-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage666 component feedback input host inspection receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage665_component_feedback_input_demo_host_surface_consumed=true" \
  "shared_feedback_input_host_inspection_receipt_materialized=true" \
  "feedback_input_host_inspection_probe_input_materialized=true" \
  "validation_dismiss_inspection_receipt_materialized=true" \
  "focus_movement_inspection_receipt_materialized=true" \
  "input_feedback_clear_inspection_receipt_materialized=true" \
  "semantic_diff_acknowledge_inspection_receipt_materialized=true" \
  "chat_composer_feedback_input_host_inspection_receipt_materialized=true" \
  "stage667_component_feedback_input_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE665_SUITE_PACKET" || ! -f "$STAGE665_SUITE_PACKET" ]]; then
  echo "cjgui stage666 component feedback input host inspection receipt suite: missing stage665 packet; set CJGUI_STAGE666_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage665_component_feedback_input_demo_host_surface_suite_version=1" \
  "shared_component_feedback_input_demo_host_surface_materialized=true" \
  "chat_composer_feedback_input_demo_host_surface_materialized=true" \
  "stage666_component_feedback_input_host_inspection_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE665_SUITE_PACKET" "$fact"
done

{
  echo "stage666_component_feedback_input_host_inspection_receipt_suite_version=1"
  echo "stage665_component_feedback_input_demo_host_surface_suite_packet=$STAGE665_SUITE_PACKET"
  echo "stage666_component_feedback_input_host_inspection_receipt_owner_passed=true"
  echo "stage665_component_feedback_input_demo_host_surface_consumed=true"
  echo "stage664_interaction_feedback_input_runtime_contract_consumed_transitively=true"
  echo "feedback_input_demo_host_surfaces_consumed=true"
  echo "shared_feedback_input_host_inspection_receipt_materialized=true"
  echo "feedback_input_host_inspection_probe_input_materialized=true"
  echo "validation_dismiss_inspection_receipt_materialized=true"
  echo "focus_movement_inspection_receipt_materialized=true"
  echo "input_feedback_clear_inspection_receipt_materialized=true"
  echo "semantic_diff_acknowledge_inspection_receipt_materialized=true"
  echo "todo_feedback_input_host_inspection_receipt_materialized=true"
  echo "settings_feedback_input_host_inspection_receipt_materialized=true"
  echo "ai_generated_settings_feedback_input_host_inspection_receipt_materialized=true"
  echo "chat_composer_feedback_input_host_inspection_receipt_materialized=true"
  echo "host_inspection_receipt_bound_to_stage665_surface=true"
  echo "feedback_input_host_inspection_checkable=true"
  echo "stage667_component_feedback_input_result_surface_refresh_prepared=true"
  echo "host_mutation=false"
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
  echo "next_route=stage667_component_feedback_input_result_surface_refresh_after_stage666"
  echo "stage666_component_feedback_input_host_inspection_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage666 component feedback input host inspection receipt suite: route_classification=feedback_input_host_inspection_ready"
echo "cjgui stage666 component feedback input host inspection receipt suite: suite_packet_path=$SUITE_PACKET"
