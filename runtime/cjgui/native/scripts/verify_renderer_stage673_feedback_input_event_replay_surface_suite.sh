#!/usr/bin/env zsh
#
# Focused suite for stage673. It consumes the stage672 event-cycle runtime
# contract packet and verifies the replayable feedback input event surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE673_TMPDIR:-/private/tmp/cjgui-stage673-stage676/stage673}"
SUITE_PACKET="$TMP_DIR/stage673-feedback-input-event-replay-surface-suite.packet"
STAGE672_SUITE_PACKET="${CJGUI_STAGE673_INPUT_PACKET:-${CJGUI_STAGE672_FEEDBACK_INPUT_DEMO_HOST_EVENT_CYCLE_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage669-stage672/stage672/stage672-feedback-input-demo-host-event-cycle-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage673_feedback_input_event_replay_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage673-feedback-input-event-replay-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage673 feedback input event replay surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed=true" \
  "shared_feedback_input_event_replay_surface_materialized=true" \
  "replayable_semantic_diff_acknowledge_result_surface_materialized=true" \
  "chat_composer_feedback_input_event_replay_surface_materialized=true" \
  "stage674_feedback_input_replay_host_inspection_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE672_SUITE_PACKET" || ! -f "$STAGE672_SUITE_PACKET" ]]; then
  echo "cjgui stage673 feedback input event replay surface suite: missing stage672 packet; set CJGUI_STAGE673_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage672_feedback_input_demo_host_event_cycle_runtime_contract_suite_version=1" \
  "shared_feedback_input_demo_host_event_cycle_runtime_contract_materialized=true" \
  "chat_composer_feedback_input_demo_host_event_cycle_runtime_surface_materialized=true" \
  "stage673_feedback_input_demo_host_event_replay_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE672_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage673_feedback_input_event_replay_surface.cj"
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage673 feedback input event replay surface suite: public or foreign declaration found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage673 feedback input event replay surface suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage673_feedback_input_event_replay_surface_suite_version=1"
  echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_suite_packet=$STAGE672_SUITE_PACKET"
  echo "stage673_feedback_input_event_replay_surface_owner_passed=true"
  echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed=true"
  echo "shared_feedback_input_event_replay_surface_materialized=true"
  echo "replayable_validation_dismiss_result_surface_materialized=true"
  echo "replayable_focus_movement_result_surface_materialized=true"
  echo "replayable_input_feedback_clear_result_surface_materialized=true"
  echo "replayable_semantic_diff_acknowledge_result_surface_materialized=true"
  echo "todo_feedback_input_event_replay_surface_materialized=true"
  echo "settings_feedback_input_event_replay_surface_materialized=true"
  echo "ai_generated_settings_feedback_input_event_replay_surface_materialized=true"
  echo "chat_composer_feedback_input_event_replay_surface_materialized=true"
  echo "stage674_feedback_input_replay_host_inspection_preview_prepared=true"
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
  echo "stage673_feedback_input_event_replay_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage673 feedback input event replay surface suite: route_classification=feedback_input_event_replay_surface_ready"
echo "cjgui stage673 feedback input event replay surface suite: suite_packet_path=$SUITE_PACKET"
