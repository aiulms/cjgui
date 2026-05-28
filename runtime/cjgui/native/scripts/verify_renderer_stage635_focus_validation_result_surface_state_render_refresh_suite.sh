#!/usr/bin/env zsh
#
# Focused suite for stage635. It consumes stage634 action/state candidates and
# verifies RenderCommand refresh receipts for result-surface feedback.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE635_TMPDIR:-/private/tmp/cjgui-stage633-stage636/stage635}"
SUITE_PACKET="$TMP_DIR/stage635-focus-validation-result-surface-state-render-refresh-suite.packet"
STAGE634_SUITE_PACKET="${CJGUI_STAGE635_INPUT_PACKET:-${CJGUI_STAGE634_FOCUS_VALIDATION_RESULT_SURFACE_ACTION_STATE_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage633-stage636/stage634/stage634-focus-validation-result-surface-action-state-adapter-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage635_focus_validation_result_surface_state_render_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage635-focus-validation-result-surface-state-render-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage635 focus validation result surface state render refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage634_focus_validation_result_surface_action_state_adapter_consumed=true" \
  "shared_result_surface_state_render_refresh_executor_materialized=true" \
  "result_surface_render_command_refresh_ledger_materialized=true" \
  "chat_composer_result_surface_render_refresh_receipt_materialized=true" \
  "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE634_SUITE_PACKET" || ! -f "$STAGE634_SUITE_PACKET" ]]; then
  echo "cjgui stage635 focus validation result surface state render refresh suite: missing stage634 packet; set CJGUI_STAGE635_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage634_focus_validation_result_surface_action_state_adapter_suite_version=1" \
  "shared_result_surface_action_state_adapter_materialized=true" \
  "chat_composer_result_surface_action_state_candidate_materialized=true" \
  "stage635_focus_validation_result_surface_state_render_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE634_SUITE_PACKET" "$fact"
done

{
  echo "stage635_focus_validation_result_surface_state_render_refresh_suite_version=1"
  echo "stage634_focus_validation_result_surface_action_state_adapter_suite_packet=$STAGE634_SUITE_PACKET"
  echo "stage635_focus_validation_result_surface_state_render_refresh_owner_passed=true"
  echo "stage634_focus_validation_result_surface_action_state_adapter_consumed=true"
  echo "stage633_focus_validation_result_surface_interaction_bridge_consumed_transitively=true"
  echo "stage632_shared_focus_validation_result_surface_runtime_contract_consumed_transitively=true"
  echo "result_surface_action_state_candidates_consumed=true"
  echo "shared_result_surface_state_render_refresh_executor_materialized=true"
  echo "result_surface_render_command_refresh_ledger_materialized=true"
  echo "validation_display_render_refresh_receipt_materialized=true"
  echo "focus_transition_render_refresh_receipt_materialized=true"
  echo "input_feedback_render_refresh_receipt_materialized=true"
  echo "todo_result_surface_render_refresh_receipt_materialized=true"
  echo "settings_result_surface_render_refresh_receipt_materialized=true"
  echo "ai_generated_settings_result_surface_render_refresh_receipt_materialized=true"
  echo "chat_composer_result_surface_render_refresh_receipt_materialized=true"
  echo "result_surface_state_render_refresh_checkable=true"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_prepared=true"
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
  echo "next_route=stage636_shared_focus_validation_result_surface_interaction_runtime_contract_after_stage635"
  echo "stage635_focus_validation_result_surface_state_render_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage635 focus validation result surface state render refresh suite: route_classification=result_surface_state_render_refresh_ready"
echo "cjgui stage635 focus validation result surface state render refresh suite: suite_packet_path=$SUITE_PACKET"
