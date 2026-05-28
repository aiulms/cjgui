#!/usr/bin/env zsh
#
# Focused suite for stage661. It consumes stage660 cycle runtime surfaces and
# verifies the shared interaction feedback input bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE661_TMPDIR:-/private/tmp/cjgui-stage661-stage664/stage661}"
SUITE_PACKET="$TMP_DIR/stage661-interaction-feedback-input-bridge-suite.packet"
STAGE660_SUITE_PACKET="${CJGUI_STAGE661_INPUT_PACKET:-${CJGUI_STAGE660_INTERACTION_FEEDBACK_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage657-stage660/stage660/stage660-interaction-feedback-cycle-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage661_interaction_feedback_input_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage661-interaction-feedback-input-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage661 interaction feedback input bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage660_interaction_feedback_cycle_executor_consumed=true" \
  "shared_interaction_feedback_input_bridge_materialized=true" \
  "chat_composer_interaction_feedback_input_bridge_materialized=true" \
  "stage662_interaction_feedback_input_intent_normalizer_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE660_SUITE_PACKET" || ! -f "$STAGE660_SUITE_PACKET" ]]; then
  echo "cjgui stage661 interaction feedback input bridge suite: missing stage660 packet; set CJGUI_STAGE661_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage660_interaction_feedback_cycle_executor_suite_version=1" \
  "shared_interaction_feedback_cycle_executor_contract_materialized=true" \
  "chat_composer_interaction_feedback_cycle_runtime_surface_materialized=true" \
  "stage661_component_host_input_result_surface_interaction_feedback_input_bridge_after_stage660_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE660_SUITE_PACKET" "$fact"
done

{
  echo "stage661_interaction_feedback_input_bridge_suite_version=1"
  echo "stage660_interaction_feedback_cycle_executor_suite_packet=$STAGE660_SUITE_PACKET"
  echo "stage661_interaction_feedback_input_bridge_owner_passed=true"
  echo "stage660_interaction_feedback_cycle_executor_consumed=true"
  echo "stage659_interaction_feedback_result_surface_consumed_transitively=true"
  echo "shared_interaction_feedback_input_bridge_materialized=true"
  echo "validation_dismiss_input_route_materialized=true"
  echo "focus_movement_input_route_materialized=true"
  echo "input_feedback_clear_input_route_materialized=true"
  echo "semantic_diff_acknowledge_input_route_materialized=true"
  echo "feedback_input_bridge_binding_ledger_materialized=true"
  echo "todo_interaction_feedback_input_bridge_materialized=true"
  echo "settings_interaction_feedback_input_bridge_materialized=true"
  echo "ai_generated_settings_interaction_feedback_input_bridge_materialized=true"
  echo "chat_composer_interaction_feedback_input_bridge_materialized=true"
  echo "interaction_feedback_input_bridge_owner_local=true"
  echo "interaction_feedback_input_bridge_non_executing=true"
  echo "stage662_interaction_feedback_input_intent_normalizer_prepared=true"
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
  echo "next_route=stage662_interaction_feedback_input_intent_normalizer_after_stage661"
  echo "stage661_interaction_feedback_input_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage661 interaction feedback input bridge suite: route_classification=input_bridge_ready"
echo "cjgui stage661 interaction feedback input bridge suite: suite_packet_path=$SUITE_PACKET"
