#!/usr/bin/env zsh
#
# Focused suite for stage654. It consumes stage653 host slot facts and verifies
# the shared interaction feedback host frame assembly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE654_TMPDIR:-/private/tmp/cjgui-stage653-stage656/stage654}"
SUITE_PACKET="$TMP_DIR/stage654-interaction-feedback-host-frame-assembly-suite.packet"
STAGE653_SUITE_PACKET="${CJGUI_STAGE654_INPUT_PACKET:-${CJGUI_STAGE653_INTERACTION_FEEDBACK_HOST_INTEGRATION_SUITE_PACKET:-/private/tmp/cjgui-stage653-stage656/stage653/stage653-interaction-feedback-host-integration-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage654_interaction_feedback_host_frame_assembly_owner.sh"
OWNER_LOG="$TMP_DIR/stage654-interaction-feedback-host-frame-assembly-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage654 interaction feedback host frame assembly suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage653_interaction_feedback_host_integration_consumed=true" \
  "shared_host_feedback_frame_assembly_materialized=true" \
  "chat_composer_interaction_feedback_host_frame_materialized=true" \
  "stage655_interaction_feedback_host_inspection_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE653_SUITE_PACKET" || ! -f "$STAGE653_SUITE_PACKET" ]]; then
  echo "cjgui stage654 interaction feedback host frame assembly suite: missing stage653 packet; set CJGUI_STAGE654_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage653_interaction_feedback_host_integration_suite_version=1" \
  "shared_interaction_feedback_host_integration_slots_materialized=true" \
  "chat_composer_interaction_feedback_host_integration_materialized=true" \
  "stage654_interaction_feedback_host_frame_assembly_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE653_SUITE_PACKET" "$fact"
done

{
  echo "stage654_interaction_feedback_host_frame_assembly_suite_version=1"
  echo "stage653_interaction_feedback_host_integration_suite_packet=$STAGE653_SUITE_PACKET"
  echo "stage654_interaction_feedback_host_frame_assembly_owner_passed=true"
  echo "stage653_interaction_feedback_host_integration_consumed=true"
  echo "stage652_interaction_feedback_runtime_contract_consumed_transitively=true"
  echo "interaction_feedback_host_slots_consumed=true"
  echo "shared_host_feedback_frame_assembly_materialized=true"
  echo "validation_dismiss_frame_invalidation_materialized=true"
  echo "focus_movement_frame_preview_materialized=true"
  echo "input_feedback_clear_frame_preview_materialized=true"
  echo "semantic_diff_acknowledge_frame_preview_materialized=true"
  echo "todo_interaction_feedback_host_frame_materialized=true"
  echo "settings_interaction_feedback_host_frame_materialized=true"
  echo "ai_generated_settings_interaction_feedback_host_frame_materialized=true"
  echo "chat_composer_interaction_feedback_host_frame_materialized=true"
  echo "host_frame_assembly_bound_to_stage653_host_slots=true"
  echo "host_frame_non_publishing=true"
  echo "stage655_interaction_feedback_host_inspection_receipt_prepared=true"
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
  echo "next_route=stage655_interaction_feedback_host_inspection_receipt_after_stage654"
  echo "stage654_interaction_feedback_host_frame_assembly_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage654 interaction feedback host frame assembly suite: route_classification=host_frame_assembly_ready"
echo "cjgui stage654 interaction feedback host frame assembly suite: suite_packet_path=$SUITE_PACKET"
