#!/usr/bin/env zsh
#
# Focused suite for stage663. It consumes normalized feedback input intents and
# verifies the state/render/focus/result-surface dry-run receipt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE663_TMPDIR:-/private/tmp/cjgui-stage661-stage664/stage663}"
SUITE_PACKET="$TMP_DIR/stage663-interaction-feedback-input-state-render-receipt-suite.packet"
STAGE662_SUITE_PACKET="${CJGUI_STAGE663_INPUT_PACKET:-${CJGUI_STAGE662_INTERACTION_FEEDBACK_INPUT_INTENT_NORMALIZER_SUITE_PACKET:-/private/tmp/cjgui-stage661-stage664/stage662/stage662-interaction-feedback-input-intent-normalizer-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage663_interaction_feedback_input_state_render_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage663-interaction-feedback-input-state-render-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage663 interaction feedback input state/render receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage662_interaction_feedback_input_intent_normalizer_consumed=true" \
  "feedback_input_state_delta_dry_run_receipt_materialized=true" \
  "feedback_input_result_surface_refresh_receipt_materialized=true" \
  "chat_composer_feedback_input_state_render_receipt_materialized=true" \
  "stage664_interaction_feedback_input_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE662_SUITE_PACKET" || ! -f "$STAGE662_SUITE_PACKET" ]]; then
  echo "cjgui stage663 interaction feedback input state/render receipt suite: missing stage662 packet; set CJGUI_STAGE663_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage662_interaction_feedback_input_intent_normalizer_suite_version=1" \
  "shared_feedback_input_intent_normalizer_materialized=true" \
  "chat_composer_feedback_input_intent_materialized=true" \
  "stage663_interaction_feedback_input_state_render_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE662_SUITE_PACKET" "$fact"
done

{
  echo "stage663_interaction_feedback_input_state_render_receipt_suite_version=1"
  echo "stage662_interaction_feedback_input_intent_normalizer_suite_packet=$STAGE662_SUITE_PACKET"
  echo "stage663_interaction_feedback_input_state_render_receipt_owner_passed=true"
  echo "stage662_interaction_feedback_input_intent_normalizer_consumed=true"
  echo "stage661_interaction_feedback_input_bridge_consumed_transitively=true"
  echo "feedback_input_state_delta_dry_run_receipt_materialized=true"
  echo "feedback_input_render_command_refresh_receipt_materialized=true"
  echo "feedback_input_focus_transition_preview_materialized=true"
  echo "feedback_input_result_surface_refresh_receipt_materialized=true"
  echo "feedback_input_semantic_diff_explain_receipt_materialized=true"
  echo "todo_feedback_input_state_render_receipt_materialized=true"
  echo "settings_feedback_input_state_render_receipt_materialized=true"
  echo "ai_generated_settings_feedback_input_state_render_receipt_materialized=true"
  echo "chat_composer_feedback_input_state_render_receipt_materialized=true"
  echo "feedback_input_state_render_receipt_checkable=true"
  echo "state_update_dry_run_only=true"
  echo "stage664_interaction_feedback_input_runtime_contract_prepared=true"
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
  echo "next_route=stage664_interaction_feedback_input_runtime_contract_after_stage663"
  echo "stage663_interaction_feedback_input_state_render_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage663 interaction feedback input state/render receipt suite: route_classification=input_state_render_receipt_ready"
echo "cjgui stage663 interaction feedback input state/render receipt suite: suite_packet_path=$SUITE_PACKET"
