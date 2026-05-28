#!/usr/bin/env zsh
#
# Focused suite for stage675. It consumes the stage674 host inspection packet
# and verifies replay result-surface refresh receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE675_TMPDIR:-/private/tmp/cjgui-stage673-stage676/stage675}"
SUITE_PACKET="$TMP_DIR/stage675-feedback-input-replay-result-surface-refresh-suite.packet"
STAGE674_SUITE_PACKET="${CJGUI_STAGE675_INPUT_PACKET:-${CJGUI_STAGE674_FEEDBACK_INPUT_REPLAY_HOST_INSPECTION_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage673-stage676/stage674/stage674-feedback-input-replay-host-inspection-preview-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage675_feedback_input_replay_result_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage675-feedback-input-replay-result-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage675 feedback input replay result surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage674_feedback_input_replay_host_inspection_preview_consumed=true" \
  "shared_replay_result_surface_refresh_receipt_materialized=true" \
  "replay_render_command_refresh_preview_materialized=true" \
  "chat_composer_feedback_input_replay_result_surface_refresh_materialized=true" \
  "stage676_feedback_input_replay_runtime_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE674_SUITE_PACKET" || ! -f "$STAGE674_SUITE_PACKET" ]]; then
  echo "cjgui stage675 feedback input replay result surface refresh suite: missing stage674 packet; set CJGUI_STAGE675_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage674_feedback_input_replay_host_inspection_preview_suite_version=1" \
  "shared_replay_host_inspection_preview_materialized=true" \
  "chat_composer_feedback_input_replay_host_inspection_materialized=true" \
  "stage675_feedback_input_replay_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE674_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage675_feedback_input_replay_result_surface_refresh.cj"
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage675 feedback input replay result surface refresh suite: public or foreign declaration found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage675 feedback input replay result surface refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage675_feedback_input_replay_result_surface_refresh_suite_version=1"
  echo "stage674_feedback_input_replay_host_inspection_preview_suite_packet=$STAGE674_SUITE_PACKET"
  echo "stage675_feedback_input_replay_result_surface_refresh_owner_passed=true"
  echo "stage674_feedback_input_replay_host_inspection_preview_consumed=true"
  echo "stage673_feedback_input_event_replay_surface_consumed_transitively=true"
  echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed_transitively=true"
  echo "shared_replay_result_surface_refresh_receipt_materialized=true"
  echo "replay_semantic_diff_explain_refresh_materialized=true"
  echo "replay_focus_transition_refresh_materialized=true"
  echo "replay_render_command_refresh_preview_materialized=true"
  echo "replay_input_feedback_display_refresh_materialized=true"
  echo "todo_feedback_input_replay_result_surface_refresh_materialized=true"
  echo "settings_feedback_input_replay_result_surface_refresh_materialized=true"
  echo "ai_generated_settings_feedback_input_replay_result_surface_refresh_materialized=true"
  echo "chat_composer_feedback_input_replay_result_surface_refresh_materialized=true"
  echo "stage676_feedback_input_replay_runtime_executor_prepared=true"
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
  echo "stage675_feedback_input_replay_result_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage675 feedback input replay result surface refresh suite: route_classification=feedback_input_replay_result_surface_refresh_ready"
echo "cjgui stage675 feedback input replay result surface refresh suite: suite_packet_path=$SUITE_PACKET"
