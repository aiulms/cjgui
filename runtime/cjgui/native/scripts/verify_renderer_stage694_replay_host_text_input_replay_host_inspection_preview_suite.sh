#!/usr/bin/env zsh
#
# Focused suite for stage694. It consumes stage693 and verifies a replay host
# inspection timeline preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE694_TMPDIR:-/private/tmp/cjgui-stage693-stage696/stage694}"
SUITE_PACKET="$TMP_DIR/stage694-replay-host-text-input-replay-host-inspection-preview-suite.packet"
STAGE693_SUITE_PACKET="${CJGUI_STAGE694_INPUT_PACKET:-${CJGUI_STAGE693_REPLAY_HOST_TEXT_INPUT_EVENT_REPLAY_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage693-stage696/stage693/stage693-replay-host-text-input-event-replay-surface-suite.packet}}"
STAGE693_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage693_replay_host_text_input_event_replay_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage694_replay_host_text_input_replay_host_inspection_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage694-replay-host-text-input-replay-host-inspection-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage694 replay host text input replay host inspection preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE693_SUITE_PACKET" ]]; then
  zsh "$STAGE693_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage693_replay_host_text_input_event_replay_surface_consumed=true" \
  "shared_replay_host_text_input_host_inspection_timeline_preview_materialized=true" \
  "replay_timeline_probe_input_contract_materialized=true" \
  "text_edit_commit_replay_host_inspection_materialized=true" \
  "submit_replay_host_inspection_materialized=true" \
  "chat_composer_replay_host_text_input_host_inspection_materialized=true" \
  "stage695_replay_host_text_input_replay_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage693_replay_host_text_input_event_replay_surface_suite_version=1" \
  "shared_replay_host_text_input_event_replay_surface_materialized=true" \
  "chat_composer_replay_host_text_input_event_replay_surface_materialized=true" \
  "stage694_replay_host_text_input_replay_host_inspection_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE693_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage694_replay_host_text_input_replay_host_inspection_preview.cj"
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage694 replay host text input replay host inspection preview suite: public or foreign declaration found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage694 replay host text input replay host inspection preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage694_replay_host_text_input_replay_host_inspection_preview_suite_version=1"
  echo "stage693_replay_host_text_input_event_replay_surface_suite_packet=$STAGE693_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage694_public_foreign_scan_passed=true"
  echo "stage694_protected_path_scan_passed=true"
  echo "stage694_replay_host_text_input_replay_host_inspection_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage694 replay host text input replay host inspection preview suite: route_classification=text_input_replay_host_inspection_preview_ready"
echo "cjgui stage694 replay host text input replay host inspection preview suite: suite_packet_path=$SUITE_PACKET"
