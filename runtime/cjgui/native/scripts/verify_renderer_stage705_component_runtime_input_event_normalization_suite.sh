#!/usr/bin/env zsh
#
# Focused suite for stage705. It consumes stage704 and verifies component
# runtime input event normalization.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE705_TMPDIR:-/private/tmp/cjgui-stage705-stage708/stage705}"
SUITE_PACKET="$TMP_DIR/stage705-component-runtime-input-event-normalization-suite.packet"
STAGE704_SUITE_PACKET="${CJGUI_STAGE705_INPUT_PACKET:-${CJGUI_STAGE704_TEXT_INPUT_COMPONENT_RUNTIME_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage701-stage704/stage704/stage704-text-input-component-runtime-cycle-executor-suite.packet}}"
STAGE704_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage704_text_input_component_runtime_cycle_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage705_component_runtime_input_event_normalization_owner.sh"
OWNER_LOG="$TMP_DIR/stage705-component-runtime-input-event-normalization-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage705 component runtime input event normalization suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE704_SUITE_PACKET" ]]; then
  zsh "$STAGE704_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage704_text_input_component_runtime_cycle_executor_consumed=true" \
  "shared_component_runtime_input_event_normalizer_materialized=true" \
  "text_edit_normalized_component_input_event_materialized=true" \
  "submit_normalized_component_input_event_materialized=true" \
  "validation_dismiss_normalized_component_input_event_materialized=true" \
  "focus_move_normalized_component_input_event_materialized=true" \
  "normalized_input_event_bound_to_component_slot_contract=true" \
  "stage706_component_runtime_action_intent_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage704_text_input_component_runtime_cycle_executor_suite_version=1" \
  "shared_text_input_component_runtime_cycle_executor_materialized=true" \
  "shared_text_input_component_runtime_contract_materialized=true" \
  "stage705_component_runtime_input_event_normalization_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE704_SUITE_PACKET" "$fact"
done

{
  echo "stage705_component_runtime_input_event_normalization_suite_version=1"
  echo "stage704_text_input_component_runtime_cycle_executor_suite_packet=$STAGE704_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage706_component_runtime_action_intent_adapter_after_stage705"
  echo "stage705_component_runtime_input_event_normalization_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage705 component runtime input event normalization suite: route_classification=component_runtime_normalized_input_ready"
echo "cjgui stage705 component runtime input event normalization suite: suite_packet_path=$SUITE_PACKET"
