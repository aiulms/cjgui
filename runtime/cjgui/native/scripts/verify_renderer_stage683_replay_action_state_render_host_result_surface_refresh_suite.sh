#!/usr/bin/env zsh
#
# Focused suite for stage683. It consumes stage682 and verifies host result-surface refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE683_TMPDIR:-/private/tmp/cjgui-stage681-stage684/stage683}"
SUITE_PACKET="$TMP_DIR/stage683-replay-action-state-render-host-result-surface-refresh-suite.packet"
STAGE682_SUITE_PACKET="${CJGUI_STAGE683_INPUT_PACKET:-${CJGUI_STAGE682_REPLAY_ACTION_STATE_RENDER_LAYOUT_FOCUS_INSPECTION_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage681-stage684/stage682/stage682-replay-action-state-render-layout-focus-inspection-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage683_replay_action_state_render_host_result_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage683-replay-action-state-render-host-result-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage683 replay action-state-render host result-surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage682_replay_action_state_render_layout_focus_inspection_receipt_consumed=true" \
  "shared_replay_host_result_surface_refresh_materialized=true" \
  "replay_host_semantic_diff_explain_refresh_materialized=true" \
  "replay_host_render_command_inspection_refresh_materialized=true" \
  "chat_composer_replay_host_result_surface_refresh_materialized=true" \
  "stage684_replay_action_state_render_host_inspection_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage682_replay_action_state_render_layout_focus_inspection_receipt_suite_version=1" \
  "shared_replay_layout_style_text_focus_inspection_receipt_materialized=true" \
  "stage683_replay_action_state_render_host_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE682_SUITE_PACKET" "$fact"
done

{
  echo "stage683_replay_action_state_render_host_result_surface_refresh_suite_version=1"
  echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_suite_packet=$STAGE682_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage683_replay_action_state_render_host_result_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage683 replay action-state-render host result-surface refresh suite: route_classification=host_result_surface_refresh_ready"
echo "cjgui stage683 replay action-state-render host result-surface refresh suite: suite_packet_path=$SUITE_PACKET"
