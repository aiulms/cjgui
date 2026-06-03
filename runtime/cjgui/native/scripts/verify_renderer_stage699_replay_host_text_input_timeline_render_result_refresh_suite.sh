#!/usr/bin/env zsh
#
# Focused suite for stage699. It consumes stage698 and verifies render/result
# refresh previews from timeline state deltas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE699_TMPDIR:-/private/tmp/cjgui-stage697-stage700/stage699}"
SUITE_PACKET="$TMP_DIR/stage699-replay-host-text-input-timeline-render-result-refresh-suite.packet"
STAGE698_SUITE_PACKET="${CJGUI_STAGE699_INPUT_PACKET:-${CJGUI_STAGE698_REPLAY_HOST_TEXT_INPUT_TIMELINE_STATE_DELTA_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage697-stage700/stage698/stage698-replay-host-text-input-timeline-state-delta-dry-run-suite.packet}}"
STAGE698_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage698_replay_host_text_input_timeline_state_delta_dry_run_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage699_replay_host_text_input_timeline_render_result_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage699-replay-host-text-input-timeline-render-result-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage699 replay host text input timeline render/result refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE698_SUITE_PACKET" ]]; then
  zsh "$STAGE698_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage698_replay_host_text_input_timeline_state_delta_dry_run_consumed=true" \
  "shared_replay_host_text_input_timeline_render_result_refresh_bridge_materialized=true" \
  "text_edit_timeline_render_command_refresh_preview_materialized=true" \
  "submit_timeline_result_surface_refresh_materialized=true" \
  "validation_timeline_feedback_refresh_materialized=true" \
  "focus_timeline_result_surface_refresh_materialized=true" \
  "timeline_semantic_diff_explain_refresh_materialized=true" \
  "stage700_replay_host_text_input_timeline_action_state_render_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage698_replay_host_text_input_timeline_state_delta_dry_run_suite_version=1" \
  "shared_replay_host_text_input_timeline_state_delta_dry_run_executor_materialized=true" \
  "chat_composer_replay_host_text_input_timeline_state_delta_surface_materialized=true" \
  "stage699_replay_host_text_input_timeline_render_result_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE698_SUITE_PACKET" "$fact"
done

{
  echo "stage699_replay_host_text_input_timeline_render_result_refresh_suite_version=1"
  echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_suite_packet=$STAGE698_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage699_replay_host_text_input_timeline_render_result_refresh_suite_passed=true"
  echo "next_route=stage700_replay_host_text_input_timeline_action_state_render_executor_after_stage699"
} > "$SUITE_PACKET"

echo "cjgui stage699 replay host text input timeline render/result refresh suite: route_classification=timeline_render_result_refresh_ready"
echo "cjgui stage699 replay host text input timeline render/result refresh suite: suite_packet_path=$SUITE_PACKET"
