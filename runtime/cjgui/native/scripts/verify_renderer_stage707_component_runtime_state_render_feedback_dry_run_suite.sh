#!/usr/bin/env zsh
#
# Focused suite for stage707. It consumes stage706 and verifies state/render
# feedback dry-run surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE707_TMPDIR:-/private/tmp/cjgui-stage705-stage708/stage707}"
SUITE_PACKET="$TMP_DIR/stage707-component-runtime-state-render-feedback-dry-run-suite.packet"
STAGE706_SUITE_PACKET="${CJGUI_STAGE707_INPUT_PACKET:-${CJGUI_STAGE706_COMPONENT_RUNTIME_ACTION_INTENT_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage705-stage708/stage706/stage706-component-runtime-action-intent-adapter-suite.packet}}"
STAGE706_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage706_component_runtime_action_intent_adapter_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage707_component_runtime_state_render_feedback_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage707-component-runtime-state-render-feedback-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage707 component runtime state render feedback dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE706_SUITE_PACKET" ]]; then
  zsh "$STAGE706_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage706_component_runtime_action_intent_adapter_consumed=true" \
  "shared_component_runtime_state_render_feedback_dry_run_materialized=true" \
  "component_runtime_state_delta_dry_run_materialized=true" \
  "component_runtime_render_command_refresh_preview_materialized=true" \
  "component_runtime_input_feedback_refresh_materialized=true" \
  "component_runtime_focus_transition_refresh_materialized=true" \
  "component_runtime_semantic_diff_explain_materialized=true" \
  "state_update_dry_run_only=true" \
  "render_command_refresh_preview_only=true" \
  "stage708_component_runtime_input_event_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage706_component_runtime_action_intent_adapter_suite_version=1" \
  "shared_component_runtime_action_intent_adapter_materialized=true" \
  "component_action_intent_non_dispatching=true" \
  "stage707_component_runtime_state_render_feedback_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE706_SUITE_PACKET" "$fact"
done

{
  echo "stage707_component_runtime_state_render_feedback_dry_run_suite_version=1"
  echo "stage706_component_runtime_action_intent_adapter_suite_packet=$STAGE706_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage708_component_runtime_input_event_cycle_executor_after_stage707"
  echo "stage707_component_runtime_state_render_feedback_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage707 component runtime state render feedback dry-run suite: route_classification=component_runtime_state_render_feedback_ready"
echo "cjgui stage707 component runtime state render feedback dry-run suite: suite_packet_path=$SUITE_PACKET"
