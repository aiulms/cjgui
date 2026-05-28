#!/usr/bin/env zsh
#
# Focused suite for stage685. It consumes stage684 and emits a text edit field model packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE685_TMPDIR:-/private/tmp/cjgui-stage685-stage688/stage685}"
SUITE_PACKET="$TMP_DIR/stage685-replay-host-text-edit-field-model-suite.packet"
STAGE684_SUITE_PACKET="${CJGUI_STAGE685_INPUT_PACKET:-${CJGUI_STAGE684_REPLAY_ACTION_STATE_RENDER_HOST_INSPECTION_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage681-stage684/stage684/stage684-replay-action-state-render-host-inspection-runtime-contract-suite.packet}}"
STAGE684_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage685_replay_host_text_edit_field_model_owner.sh"
OWNER_LOG="$TMP_DIR/stage685-replay-host-text-edit-field-model-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage685 replay host text edit field model suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE684_SUITE_PACKET" ]]; then
  CJGUI_STAGE684_TMPDIR="/private/tmp/cjgui-stage681-stage684/stage684" zsh "$STAGE684_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage684_replay_action_state_render_host_inspection_runtime_contract_consumed=true" \
  "shared_replay_host_text_edit_field_model_materialized=true" \
  "replay_host_text_value_model_materialized=true" \
  "replay_host_text_selection_model_materialized=true" \
  "replay_host_caret_model_materialized=true" \
  "replay_host_validation_preview_model_materialized=true" \
  "replay_host_submit_affordance_model_materialized=true" \
  "chat_composer_replay_host_text_edit_field_model_materialized=true" \
  "future_per_demo_text_edit_field_model_template_need_reduced=true" \
  "stage686_replay_host_text_edit_state_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage684_replay_action_state_render_host_inspection_runtime_contract_suite_version=1" \
  "shared_replay_action_state_render_host_inspection_runtime_contract_materialized=true" \
  "shared_replay_host_inspection_execution_receipt_contract_materialized=true" \
  "stage685_replay_action_state_render_host_input_feedback_loop_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE684_SUITE_PACKET" "$fact"
done

{
  echo "stage685_replay_host_text_edit_field_model_suite_version=1"
  echo "stage684_replay_action_state_render_host_inspection_runtime_contract_suite_packet=$STAGE684_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage685_replay_host_text_edit_field_model_suite_passed=true"
  echo "next_route=stage686_replay_host_text_edit_state_dry_run_after_stage685"
} > "$SUITE_PACKET"

echo "cjgui stage685 replay host text edit field model suite: route_classification=text_edit_field_model_ready"
echo "cjgui stage685 replay host text edit field model suite: suite_packet_path=$SUITE_PACKET"
