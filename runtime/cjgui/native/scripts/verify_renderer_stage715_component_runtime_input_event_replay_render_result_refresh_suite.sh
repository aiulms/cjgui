#!/usr/bin/env zsh
#
# Focused suite for stage715. It consumes stage714 and verifies render/result refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE715_TMPDIR:-/private/tmp/cjgui-stage713-stage716/stage715}"
SUITE_PACKET="$TMP_DIR/stage715-component-runtime-input-event-replay-render-result-refresh-suite.packet"
STAGE714_SUITE_PACKET="${CJGUI_STAGE715_INPUT_PACKET:-${CJGUI_STAGE714_COMPONENT_RUNTIME_INPUT_EVENT_REPLAY_STATE_DELTA_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage713-stage716/stage714/stage714-component-runtime-input-event-replay-state-delta-dry-run-suite.packet}}"
STAGE714_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage714_component_runtime_input_event_replay_state_delta_dry_run_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage715_component_runtime_input_event_replay_render_result_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage715-component-runtime-input-event-replay-render-result-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage715 component runtime input event replay render/result refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE714_SUITE_PACKET" ]]; then
  zsh "$STAGE714_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage714_component_runtime_input_event_replay_state_delta_dry_run_consumed=true" \
  "shared_component_runtime_input_event_replay_render_result_refresh_bridge_materialized=true" \
  "component_replay_text_edit_render_command_refresh_preview_materialized=true" \
  "component_replay_submit_result_surface_refresh_materialized=true" \
  "component_replay_semantic_diff_explain_refresh_materialized=true" \
  "stage716_component_runtime_input_event_replay_action_state_render_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage714_component_runtime_input_event_replay_state_delta_dry_run_suite_version=1" \
  "shared_component_runtime_input_event_replay_state_delta_dry_run_executor_materialized=true" \
  "stage715_component_runtime_input_event_replay_render_result_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE714_SUITE_PACKET" "$fact"
done

{
  echo "stage715_component_runtime_input_event_replay_render_result_refresh_suite_version=1"
  echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_suite_packet=$STAGE714_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage716_component_runtime_input_event_replay_action_state_render_executor_after_stage715"
  echo "stage715_component_runtime_input_event_replay_render_result_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage715 component runtime input event replay render/result refresh suite: route_classification=component_runtime_input_event_replay_render_result_ready"
echo "cjgui stage715 component runtime input event replay render/result refresh suite: suite_packet_path=$SUITE_PACKET"
