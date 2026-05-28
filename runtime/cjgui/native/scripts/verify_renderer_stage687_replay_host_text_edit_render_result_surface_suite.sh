#!/usr/bin/env zsh
#
# Focused suite for stage687. It consumes stage686 and emits render/result surface evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE687_TMPDIR:-/private/tmp/cjgui-stage685-stage688/stage687}"
SUITE_PACKET="$TMP_DIR/stage687-replay-host-text-edit-render-result-surface-suite.packet"
STAGE686_SUITE_PACKET="${CJGUI_STAGE687_INPUT_PACKET:-${CJGUI_STAGE686_REPLAY_HOST_TEXT_EDIT_STATE_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage685-stage688/stage686/stage686-replay-host-text-edit-state-dry-run-suite.packet}}"
STAGE686_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage686_replay_host_text_edit_state_dry_run_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage687_replay_host_text_edit_render_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage687-replay-host-text-edit-render-result-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage687 replay host text edit render/result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE686_SUITE_PACKET" ]]; then
  zsh "$STAGE686_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage686_replay_host_text_edit_state_dry_run_consumed=true" \
  "shared_replay_host_text_edit_render_result_surface_materialized=true" \
  "text_run_render_command_refresh_preview_materialized=true" \
  "caret_selection_render_command_refresh_preview_materialized=true" \
  "validation_feedback_render_command_refresh_preview_materialized=true" \
  "focus_feedback_result_surface_refresh_materialized=true" \
  "submit_affordance_result_surface_refresh_materialized=true" \
  "chat_composer_replay_host_text_edit_render_result_surface_materialized=true" \
  "stage688_replay_host_text_input_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage686_replay_host_text_edit_state_dry_run_suite_version=1" \
  "shared_replay_host_text_edit_operation_ledger_materialized=true" \
  "stage687_replay_host_text_edit_render_result_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE686_SUITE_PACKET" "$fact"
done

{
  echo "stage687_replay_host_text_edit_render_result_surface_suite_version=1"
  echo "stage686_replay_host_text_edit_state_dry_run_suite_packet=$STAGE686_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage687_replay_host_text_edit_render_result_surface_suite_passed=true"
  echo "next_route=stage688_replay_host_text_input_runtime_contract_after_stage687"
} > "$SUITE_PACKET"

echo "cjgui stage687 replay host text edit render/result surface suite: route_classification=text_edit_render_result_surface_ready"
echo "cjgui stage687 replay host text edit render/result surface suite: suite_packet_path=$SUITE_PACKET"
