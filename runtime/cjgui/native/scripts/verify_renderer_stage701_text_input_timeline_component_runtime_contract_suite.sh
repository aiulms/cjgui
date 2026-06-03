#!/usr/bin/env zsh
#
# Focused suite for stage701. It consumes stage700 and verifies the text input
# timeline component runtime contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE701_TMPDIR:-/private/tmp/cjgui-stage701-stage704/stage701}"
SUITE_PACKET="$TMP_DIR/stage701-text-input-timeline-component-runtime-contract-suite.packet"
STAGE700_SUITE_PACKET="${CJGUI_STAGE701_INPUT_PACKET:-${CJGUI_STAGE700_REPLAY_HOST_TEXT_INPUT_TIMELINE_ACTION_STATE_RENDER_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage697-stage700/stage700/stage700-replay-host-text-input-timeline-action-state-render-executor-suite.packet}}"
STAGE700_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage700_replay_host_text_input_timeline_action_state_render_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage701_text_input_timeline_component_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage701-text-input-timeline-component-runtime-contract-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage701 text input timeline component runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE700_SUITE_PACKET" ]]; then
  zsh "$STAGE700_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage700_replay_host_text_input_timeline_action_state_render_executor_consumed=true" \
  "shared_text_input_timeline_component_runtime_contract_materialized=true" \
  "text_value_component_slot_contract_materialized=true" \
  "text_submit_action_slot_contract_materialized=true" \
  "validation_feedback_component_slot_contract_materialized=true" \
  "focus_transition_component_slot_contract_materialized=true" \
  "render_result_component_slot_contract_materialized=true" \
  "stage702_text_input_component_slot_binding_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage700_replay_host_text_input_timeline_action_state_render_executor_suite_version=1" \
  "shared_replay_host_text_input_timeline_action_state_render_executor_materialized=true" \
  "shared_replay_host_text_input_timeline_action_state_render_runtime_contract_materialized=true" \
  "stage701_text_input_timeline_component_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE700_SUITE_PACKET" "$fact"
done

{
  echo "stage701_text_input_timeline_component_runtime_contract_suite_version=1"
  echo "stage700_replay_host_text_input_timeline_action_state_render_executor_suite_packet=$STAGE700_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage702_text_input_component_slot_binding_adapter_after_stage701"
  echo "stage701_text_input_timeline_component_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage701 text input timeline component runtime contract suite: route_classification=component_runtime_contract_ready"
echo "cjgui stage701 text input timeline component runtime contract suite: suite_packet_path=$SUITE_PACKET"
