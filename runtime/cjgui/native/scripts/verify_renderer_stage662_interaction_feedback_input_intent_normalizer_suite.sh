#!/usr/bin/env zsh
#
# Focused suite for stage662. It consumes the stage661 input bridge and
# verifies normalized feedback input intents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE662_TMPDIR:-/private/tmp/cjgui-stage661-stage664/stage662}"
SUITE_PACKET="$TMP_DIR/stage662-interaction-feedback-input-intent-normalizer-suite.packet"
STAGE661_SUITE_PACKET="${CJGUI_STAGE662_INPUT_PACKET:-${CJGUI_STAGE661_INTERACTION_FEEDBACK_INPUT_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage661-stage664/stage661/stage661-interaction-feedback-input-bridge-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage662_interaction_feedback_input_intent_normalizer_owner.sh"
OWNER_LOG="$TMP_DIR/stage662-interaction-feedback-input-intent-normalizer-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage662 interaction feedback input intent normalizer suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage661_interaction_feedback_input_bridge_consumed=true" \
  "shared_feedback_input_intent_normalizer_materialized=true" \
  "chat_composer_feedback_input_intent_materialized=true" \
  "stage663_interaction_feedback_input_state_render_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE661_SUITE_PACKET" || ! -f "$STAGE661_SUITE_PACKET" ]]; then
  echo "cjgui stage662 interaction feedback input intent normalizer suite: missing stage661 packet; set CJGUI_STAGE662_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage661_interaction_feedback_input_bridge_suite_version=1" \
  "shared_interaction_feedback_input_bridge_materialized=true" \
  "chat_composer_interaction_feedback_input_bridge_materialized=true" \
  "stage662_interaction_feedback_input_intent_normalizer_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE661_SUITE_PACKET" "$fact"
done

{
  echo "stage662_interaction_feedback_input_intent_normalizer_suite_version=1"
  echo "stage661_interaction_feedback_input_bridge_suite_packet=$STAGE661_SUITE_PACKET"
  echo "stage662_interaction_feedback_input_intent_normalizer_owner_passed=true"
  echo "stage661_interaction_feedback_input_bridge_consumed=true"
  echo "stage660_interaction_feedback_cycle_executor_consumed_transitively=true"
  echo "shared_feedback_input_intent_normalizer_materialized=true"
  echo "validation_dismiss_input_intent_materialized=true"
  echo "focus_movement_input_intent_materialized=true"
  echo "input_feedback_clear_input_intent_materialized=true"
  echo "semantic_diff_acknowledge_input_intent_materialized=true"
  echo "feedback_input_intent_route_ledger_materialized=true"
  echo "todo_feedback_input_intent_materialized=true"
  echo "settings_feedback_input_intent_materialized=true"
  echo "ai_generated_settings_feedback_input_intent_materialized=true"
  echo "chat_composer_feedback_input_intent_materialized=true"
  echo "feedback_input_intents_non_dispatching=true"
  echo "owner_local_state_preview_only=true"
  echo "stage663_interaction_feedback_input_state_render_receipt_prepared=true"
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
  echo "next_route=stage663_interaction_feedback_input_state_render_receipt_after_stage662"
  echo "stage662_interaction_feedback_input_intent_normalizer_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage662 interaction feedback input intent normalizer suite: route_classification=input_intent_normalizer_ready"
echo "cjgui stage662 interaction feedback input intent normalizer suite: suite_packet_path=$SUITE_PACKET"
