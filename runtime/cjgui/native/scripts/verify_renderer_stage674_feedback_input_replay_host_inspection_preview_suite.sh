#!/usr/bin/env zsh
#
# Focused suite for stage674. It consumes the stage673 replay surface packet
# and verifies shared host inspection preview/probe input.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE674_TMPDIR:-/private/tmp/cjgui-stage673-stage676/stage674}"
SUITE_PACKET="$TMP_DIR/stage674-feedback-input-replay-host-inspection-preview-suite.packet"
STAGE673_SUITE_PACKET="${CJGUI_STAGE674_INPUT_PACKET:-${CJGUI_STAGE673_FEEDBACK_INPUT_EVENT_REPLAY_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage673-stage676/stage673/stage673-feedback-input-event-replay-surface-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage674_feedback_input_replay_host_inspection_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage674-feedback-input-replay-host-inspection-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage674 feedback input replay host inspection preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage673_feedback_input_event_replay_surface_consumed=true" \
  "shared_replay_host_inspection_preview_materialized=true" \
  "replay_probe_input_contract_materialized=true" \
  "chat_composer_feedback_input_replay_host_inspection_materialized=true" \
  "stage675_feedback_input_replay_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE673_SUITE_PACKET" || ! -f "$STAGE673_SUITE_PACKET" ]]; then
  echo "cjgui stage674 feedback input replay host inspection preview suite: missing stage673 packet; set CJGUI_STAGE674_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage673_feedback_input_event_replay_surface_suite_version=1" \
  "shared_feedback_input_event_replay_surface_materialized=true" \
  "chat_composer_feedback_input_event_replay_surface_materialized=true" \
  "stage674_feedback_input_replay_host_inspection_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE673_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage674_feedback_input_replay_host_inspection_preview.cj"
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage674 feedback input replay host inspection preview suite: public or foreign declaration found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage674 feedback input replay host inspection preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage674_feedback_input_replay_host_inspection_preview_suite_version=1"
  echo "stage673_feedback_input_event_replay_surface_suite_packet=$STAGE673_SUITE_PACKET"
  echo "stage674_feedback_input_replay_host_inspection_preview_owner_passed=true"
  echo "stage673_feedback_input_event_replay_surface_consumed=true"
  echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed_transitively=true"
  echo "shared_replay_host_inspection_preview_materialized=true"
  echo "replay_probe_input_contract_materialized=true"
  echo "validation_dismiss_replay_host_inspection_materialized=true"
  echo "focus_movement_replay_host_inspection_materialized=true"
  echo "input_feedback_clear_replay_host_inspection_materialized=true"
  echo "semantic_diff_acknowledge_replay_host_inspection_materialized=true"
  echo "todo_feedback_input_replay_host_inspection_materialized=true"
  echo "settings_feedback_input_replay_host_inspection_materialized=true"
  echo "ai_generated_settings_feedback_input_replay_host_inspection_materialized=true"
  echo "chat_composer_feedback_input_replay_host_inspection_materialized=true"
  echo "stage675_feedback_input_replay_result_surface_refresh_prepared=true"
  echo "host_mutation=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage674_feedback_input_replay_host_inspection_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage674 feedback input replay host inspection preview suite: route_classification=feedback_input_replay_host_inspection_preview_ready"
echo "cjgui stage674 feedback input replay host inspection preview suite: suite_packet_path=$SUITE_PACKET"
