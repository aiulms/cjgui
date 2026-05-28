#!/usr/bin/env zsh
#
# Focused suite for stage682. It consumes stage681 and verifies layout/focus inspection receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE682_TMPDIR:-/private/tmp/cjgui-stage681-stage684/stage682}"
SUITE_PACKET="$TMP_DIR/stage682-replay-action-state-render-layout-focus-inspection-receipt-suite.packet"
STAGE681_SUITE_PACKET="${CJGUI_STAGE682_INPUT_PACKET:-${CJGUI_STAGE681_REPLAY_ACTION_STATE_RENDER_DEMO_HOST_INSPECTION_SUITE_PACKET:-/private/tmp/cjgui-stage681-stage684/stage681/stage681-replay-action-state-render-demo-host-inspection-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage682-replay-action-state-render-layout-focus-inspection-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage682 replay action-state-render layout/focus inspection receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage681_replay_action_state_render_demo_host_inspection_consumed=true" \
  "shared_replay_layout_style_text_focus_inspection_receipt_materialized=true" \
  "replay_layout_slot_inspection_receipt_materialized=true" \
  "replay_text_run_inspection_receipt_materialized=true" \
  "chat_composer_replay_layout_focus_inspection_receipt_materialized=true" \
  "stage683_replay_action_state_render_host_result_surface_refresh_prepared=true" \
  "layout_engine_enabled=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage681_replay_action_state_render_demo_host_inspection_suite_version=1" \
  "shared_replay_action_state_render_host_inspection_preview_materialized=true" \
  "stage682_replay_action_state_render_layout_focus_inspection_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE681_SUITE_PACKET" "$fact"
done

{
  echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_suite_version=1"
  echo "stage681_replay_action_state_render_demo_host_inspection_suite_packet=$STAGE681_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage682 replay action-state-render layout/focus inspection receipt suite: route_classification=layout_focus_inspection_ready"
echo "cjgui stage682 replay action-state-render layout/focus inspection receipt suite: suite_packet_path=$SUITE_PACKET"
