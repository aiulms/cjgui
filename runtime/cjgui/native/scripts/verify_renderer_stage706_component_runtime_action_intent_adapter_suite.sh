#!/usr/bin/env zsh
#
# Focused suite for stage706. It consumes stage705 and verifies the
# non-dispatching component runtime action intent adapter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE706_TMPDIR:-/private/tmp/cjgui-stage705-stage708/stage706}"
SUITE_PACKET="$TMP_DIR/stage706-component-runtime-action-intent-adapter-suite.packet"
STAGE705_SUITE_PACKET="${CJGUI_STAGE706_INPUT_PACKET:-${CJGUI_STAGE705_COMPONENT_RUNTIME_INPUT_EVENT_NORMALIZATION_SUITE_PACKET:-/private/tmp/cjgui-stage705-stage708/stage705/stage705-component-runtime-input-event-normalization-suite.packet}}"
STAGE705_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage705_component_runtime_input_event_normalization_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage706_component_runtime_action_intent_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage706-component-runtime-action-intent-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage706 component runtime action intent adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE705_SUITE_PACKET" ]]; then
  zsh "$STAGE705_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage705_component_runtime_input_event_normalization_consumed=true" \
  "shared_component_runtime_action_intent_adapter_materialized=true" \
  "text_edit_component_action_intent_materialized=true" \
  "submit_component_action_intent_materialized=true" \
  "validation_dismiss_component_action_intent_materialized=true" \
  "focus_move_component_action_intent_materialized=true" \
  "component_action_intent_non_dispatching=true" \
  "stage707_component_runtime_state_render_feedback_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage705_component_runtime_input_event_normalization_suite_version=1" \
  "shared_component_runtime_input_event_normalizer_materialized=true" \
  "stage706_component_runtime_action_intent_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE705_SUITE_PACKET" "$fact"
done

{
  echo "stage706_component_runtime_action_intent_adapter_suite_version=1"
  echo "stage705_component_runtime_input_event_normalization_suite_packet=$STAGE705_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage707_component_runtime_state_render_feedback_dry_run_after_stage706"
  echo "stage706_component_runtime_action_intent_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage706 component runtime action intent adapter suite: route_classification=component_runtime_action_intent_ready"
echo "cjgui stage706 component runtime action intent adapter suite: suite_packet_path=$SUITE_PACKET"
