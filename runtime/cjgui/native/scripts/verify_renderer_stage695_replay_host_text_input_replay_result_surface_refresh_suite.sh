#!/usr/bin/env zsh
#
# Focused suite for stage695. It consumes stage694 and verifies replay result
# surface refresh receipts for text input timeline inspection.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE695_TMPDIR:-/private/tmp/cjgui-stage693-stage696/stage695}"
SUITE_PACKET="$TMP_DIR/stage695-replay-host-text-input-replay-result-surface-refresh-suite.packet"
STAGE694_SUITE_PACKET="${CJGUI_STAGE695_INPUT_PACKET:-${CJGUI_STAGE694_REPLAY_HOST_TEXT_INPUT_REPLAY_HOST_INSPECTION_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage693-stage696/stage694/stage694-replay-host-text-input-replay-host-inspection-preview-suite.packet}}"
STAGE694_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage694_replay_host_text_input_replay_host_inspection_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage695_replay_host_text_input_replay_result_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage695-replay-host-text-input-replay-result-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage695 replay host text input replay result surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE694_SUITE_PACKET" ]]; then
  zsh "$STAGE694_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage694_replay_host_text_input_replay_host_inspection_preview_consumed=true" \
  "shared_replay_host_text_input_replay_result_surface_refresh_receipt_materialized=true" \
  "replay_text_edit_value_feedback_refresh_materialized=true" \
  "replay_submit_affordance_refresh_materialized=true" \
  "replay_validation_feedback_refresh_materialized=true" \
  "replay_focus_transition_refresh_materialized=true" \
  "chat_composer_replay_host_text_input_replay_result_surface_refresh_materialized=true" \
  "stage696_replay_host_text_input_replay_timeline_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage694_replay_host_text_input_replay_host_inspection_preview_suite_version=1" \
  "shared_replay_host_text_input_host_inspection_timeline_preview_materialized=true" \
  "chat_composer_replay_host_text_input_host_inspection_materialized=true" \
  "stage695_replay_host_text_input_replay_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE694_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage695_replay_host_text_input_replay_result_surface_refresh.cj"
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage695 replay host text input replay result surface refresh suite: public or foreign declaration found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage695 replay host text input replay result surface refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage695_replay_host_text_input_replay_result_surface_refresh_suite_version=1"
  echo "stage694_replay_host_text_input_replay_host_inspection_preview_suite_packet=$STAGE694_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage695_public_foreign_scan_passed=true"
  echo "stage695_protected_path_scan_passed=true"
  echo "stage695_replay_host_text_input_replay_result_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage695 replay host text input replay result surface refresh suite: route_classification=text_input_replay_result_surface_refresh_ready"
echo "cjgui stage695 replay host text input replay result surface refresh suite: suite_packet_path=$SUITE_PACKET"
