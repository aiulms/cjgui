#!/usr/bin/env zsh
#
# Focused suite for stage686. It consumes the stage685 text edit field model packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE686_TMPDIR:-/private/tmp/cjgui-stage685-stage688/stage686}"
SUITE_PACKET="$TMP_DIR/stage686-replay-host-text-edit-state-dry-run-suite.packet"
STAGE685_SUITE_PACKET="${CJGUI_STAGE686_INPUT_PACKET:-${CJGUI_STAGE685_REPLAY_HOST_TEXT_EDIT_FIELD_MODEL_SUITE_PACKET:-/private/tmp/cjgui-stage685-stage688/stage685/stage685-replay-host-text-edit-field-model-suite.packet}}"
STAGE685_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage685_replay_host_text_edit_field_model_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage686_replay_host_text_edit_state_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage686-replay-host-text-edit-state-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage686 replay host text edit state dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE685_SUITE_PACKET" ]]; then
  zsh "$STAGE685_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage685_replay_host_text_edit_field_model_consumed=true" \
  "shared_replay_host_text_edit_operation_ledger_materialized=true" \
  "text_insert_operation_dry_run_materialized=true" \
  "text_delete_operation_dry_run_materialized=true" \
  "text_submit_operation_dry_run_materialized=true" \
  "focus_move_operation_dry_run_materialized=true" \
  "selection_caret_state_delta_dry_run_materialized=true" \
  "validation_feedback_state_delta_dry_run_materialized=true" \
  "chat_composer_replay_host_text_edit_state_receipt_materialized=true" \
  "stage687_replay_host_text_edit_render_result_surface_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage685_replay_host_text_edit_field_model_suite_version=1" \
  "shared_replay_host_text_edit_field_model_materialized=true" \
  "stage686_replay_host_text_edit_state_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE685_SUITE_PACKET" "$fact"
done

{
  echo "stage686_replay_host_text_edit_state_dry_run_suite_version=1"
  echo "stage685_replay_host_text_edit_field_model_suite_packet=$STAGE685_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage686_replay_host_text_edit_state_dry_run_suite_passed=true"
  echo "next_route=stage687_replay_host_text_edit_render_result_surface_after_stage686"
} > "$SUITE_PACKET"

echo "cjgui stage686 replay host text edit state dry-run suite: route_classification=text_edit_state_dry_run_ready"
echo "cjgui stage686 replay host text edit state dry-run suite: suite_packet_path=$SUITE_PACKET"
