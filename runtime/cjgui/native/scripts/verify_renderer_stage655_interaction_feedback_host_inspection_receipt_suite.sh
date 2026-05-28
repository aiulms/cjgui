#!/usr/bin/env zsh
#
# Focused suite for stage655. It consumes stage654 frame facts and verifies
# shared interaction feedback host inspection receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE655_TMPDIR:-/private/tmp/cjgui-stage653-stage656/stage655}"
SUITE_PACKET="$TMP_DIR/stage655-interaction-feedback-host-inspection-receipt-suite.packet"
STAGE654_SUITE_PACKET="${CJGUI_STAGE655_INPUT_PACKET:-${CJGUI_STAGE654_INTERACTION_FEEDBACK_HOST_FRAME_ASSEMBLY_SUITE_PACKET:-/private/tmp/cjgui-stage653-stage656/stage654/stage654-interaction-feedback-host-frame-assembly-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage655_interaction_feedback_host_inspection_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage655-interaction-feedback-host-inspection-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage655 interaction feedback host inspection receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage654_interaction_feedback_host_frame_assembly_consumed=true" \
  "shared_interaction_feedback_host_inspection_receipt_materialized=true" \
  "chat_composer_interaction_feedback_host_inspection_receipt_materialized=true" \
  "stage656_interaction_feedback_host_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE654_SUITE_PACKET" || ! -f "$STAGE654_SUITE_PACKET" ]]; then
  echo "cjgui stage655 interaction feedback host inspection receipt suite: missing stage654 packet; set CJGUI_STAGE655_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage654_interaction_feedback_host_frame_assembly_suite_version=1" \
  "shared_host_feedback_frame_assembly_materialized=true" \
  "chat_composer_interaction_feedback_host_frame_materialized=true" \
  "stage655_interaction_feedback_host_inspection_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE654_SUITE_PACKET" "$fact"
done

{
  echo "stage655_interaction_feedback_host_inspection_receipt_suite_version=1"
  echo "stage654_interaction_feedback_host_frame_assembly_suite_packet=$STAGE654_SUITE_PACKET"
  echo "stage655_interaction_feedback_host_inspection_receipt_owner_passed=true"
  echo "stage654_interaction_feedback_host_frame_assembly_consumed=true"
  echo "stage653_interaction_feedback_host_integration_consumed_transitively=true"
  echo "stage652_interaction_feedback_runtime_contract_consumed_transitively=true"
  echo "host_feedback_frames_consumed=true"
  echo "shared_interaction_feedback_host_inspection_receipt_materialized=true"
  echo "validation_dismiss_host_inspection_receipt_materialized=true"
  echo "focus_movement_host_inspection_receipt_materialized=true"
  echo "input_feedback_clear_host_inspection_receipt_materialized=true"
  echo "semantic_diff_acknowledge_host_inspection_receipt_materialized=true"
  echo "host_inspection_probe_input_materialized=true"
  echo "todo_interaction_feedback_host_inspection_receipt_materialized=true"
  echo "settings_interaction_feedback_host_inspection_receipt_materialized=true"
  echo "ai_generated_settings_interaction_feedback_host_inspection_receipt_materialized=true"
  echo "chat_composer_interaction_feedback_host_inspection_receipt_materialized=true"
  echo "host_inspection_receipt_bound_to_stage654_frames=true"
  echo "stage656_interaction_feedback_host_runtime_contract_prepared=true"
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
  echo "next_route=stage656_interaction_feedback_host_runtime_contract_after_stage655"
  echo "stage655_interaction_feedback_host_inspection_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage655 interaction feedback host inspection receipt suite: route_classification=host_inspection_receipt_ready"
echo "cjgui stage655 interaction feedback host inspection receipt suite: suite_packet_path=$SUITE_PACKET"
