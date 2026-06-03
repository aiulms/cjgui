#!/usr/bin/env zsh
#
# Focused suite for stage717 replay visual preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE717_TMPDIR:-/private/tmp/cjgui-stage717-stage720/stage717}"
SUITE_PACKET="$TMP_DIR/stage717-replay-visual-preview-suite.packet"
STAGE716_SUITE_PACKET="${CJGUI_STAGE717_INPUT_PACKET:-${CJGUI_STAGE716_COMPONENT_RUNTIME_INPUT_EVENT_REPLAY_ACTION_STATE_RENDER_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage713-stage716/stage716/stage716-component-runtime-input-event-replay-action-state-render-executor-suite.packet}}"
STAGE716_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage716_component_runtime_input_event_replay_action_state_render_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage717_replay_visual_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage717-replay-visual-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage717 replay visual preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE716_SUITE_PACKET" ]]; then
  zsh "$STAGE716_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage716_component_runtime_input_event_replay_action_state_render_executor_consumed=true" \
  "shared_replay_layout_style_text_focus_preview_materialized=true" \
  "replay_layout_constraint_ledger_materialized=true" \
  "replay_style_token_ledger_materialized=true" \
  "replay_text_run_ledger_materialized=true" \
  "replay_focus_target_ledger_materialized=true" \
  "stage718_replay_style_focus_resolver_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage716_component_runtime_input_event_replay_action_state_render_executor_suite_version=1" \
  "shared_component_runtime_input_event_replay_action_state_render_executor_materialized=true" \
  "stage717_component_runtime_input_event_replay_action_state_render_layout_style_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE716_SUITE_PACKET" "$fact"
done

{
  echo "stage717_replay_visual_preview_suite_version=1"
  echo "stage716_component_runtime_input_event_replay_action_state_render_executor_suite_packet=$STAGE716_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage717_replay_visual_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage717 replay visual preview suite: route_classification=replay_visual_preview_ready"
echo "cjgui stage717 replay visual preview suite: suite_packet_path=$SUITE_PACKET"
