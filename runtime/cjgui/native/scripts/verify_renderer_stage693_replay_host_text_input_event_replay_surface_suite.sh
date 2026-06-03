#!/usr/bin/env zsh
#
# Focused suite for stage693. It consumes stage692 and verifies the replayable
# text input event surface without executing a real input pipeline.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE693_TMPDIR:-/private/tmp/cjgui-stage693-stage696/stage693}"
SUITE_PACKET="$TMP_DIR/stage693-replay-host-text-input-event-replay-surface-suite.packet"
STAGE692_SUITE_PACKET="${CJGUI_STAGE693_INPUT_PACKET:-${CJGUI_STAGE692_REPLAY_HOST_TEXT_INPUT_DEMO_HOST_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage689-stage692/stage692/stage692-replay-host-text-input-demo-host-cycle-executor-suite.packet}}"
STAGE692_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage692_replay_host_text_input_demo_host_cycle_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage693_replay_host_text_input_event_replay_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage693-replay-host-text-input-event-replay-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage693 replay host text input event replay surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE692_SUITE_PACKET" ]]; then
  zsh "$STAGE692_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage692_replay_host_text_input_demo_host_cycle_executor_consumed=true" \
  "shared_replay_host_text_input_event_replay_surface_materialized=true" \
  "replayable_text_edit_commit_result_surface_materialized=true" \
  "replayable_submit_result_surface_materialized=true" \
  "replayable_validation_dismiss_result_surface_materialized=true" \
  "replayable_focus_move_result_surface_materialized=true" \
  "chat_composer_replay_host_text_input_event_replay_surface_materialized=true" \
  "stage694_replay_host_text_input_replay_host_inspection_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage692_replay_host_text_input_demo_host_cycle_executor_suite_version=1" \
  "shared_replay_host_text_input_demo_host_cycle_executor_materialized=true" \
  "chat_composer_replay_host_text_input_demo_host_cycle_runtime_surface_materialized=true" \
  "stage693_replay_host_text_input_event_replay_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE692_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage693_replay_host_text_input_event_replay_surface.cj"
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage693 replay host text input event replay surface suite: public or foreign declaration found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage693 replay host text input event replay surface suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage693_replay_host_text_input_event_replay_surface_suite_version=1"
  echo "stage692_replay_host_text_input_demo_host_cycle_executor_suite_packet=$STAGE692_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage693_public_foreign_scan_passed=true"
  echo "stage693_protected_path_scan_passed=true"
  echo "stage693_replay_host_text_input_event_replay_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage693 replay host text input event replay surface suite: route_classification=text_input_event_replay_surface_ready"
echo "cjgui stage693 replay host text input event replay surface suite: suite_packet_path=$SUITE_PACKET"
