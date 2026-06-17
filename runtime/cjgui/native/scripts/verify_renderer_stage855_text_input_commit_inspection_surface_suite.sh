#!/usr/bin/env zsh
#
# Focused suite for stage855. It consumes stage854 and records demo-host commit inspection surface facts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE855_TMPDIR:-/private/tmp/cjgui-stage853-stage856/stage855}"
SUITE_PACKET="$TMP_DIR/stage855-text-input-commit-inspection-surface-suite.packet"
STAGE854_SUITE_PACKET="${CJGUI_STAGE855_INPUT_PACKET:-${CJGUI_STAGE854_TEXT_INPUT_COMMIT_ROLLBACK_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage853-stage856/stage854/stage854-text-input-commit-rollback-snapshot-suite.packet}}"
STAGE854_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage854_text_input_commit_rollback_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage855_text_input_commit_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage855-text-input-commit-inspection-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage855 text input commit inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE854_SUITE_PACKET" ]] || ! grep -F "stage854_text_input_commit_rollback_snapshot_suite_passed=true" "$STAGE854_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE854_TMPDIR="$TMP_DIR/stage854" zsh "$STAGE854_SUITE_SCRIPT" >/dev/null
  STAGE854_SUITE_PACKET="$TMP_DIR/stage854/stage854-text-input-commit-rollback-snapshot-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage854_text_input_commit_rollback_snapshot_consumed=true" \
  "text_input_commit_inspection_row_model_materialized=true" \
  "text_input_not_published_status_banner_materialized=true" \
  "todo_text_input_commit_inspection_surface_materialized=true" \
  "settings_text_input_commit_inspection_surface_materialized=true" \
  "ai_generated_settings_text_input_commit_inspection_surface_materialized=true" \
  "chat_composer_text_input_commit_inspection_surface_materialized=true" \
  "file_browser_text_input_commit_inspection_surface_materialized=true" \
  "stage856_text_input_commit_runtime_manager_prepared=true" \
  "text_input_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage854_text_input_commit_rollback_snapshot_suite_passed=true" \
  "text_input_not_published_receipt_materialized=true" \
  "stage855_text_input_commit_inspection_surface_prepared=true" \
  "text_input_commit_committed=false"; do
  require_file_fact "$STAGE854_SUITE_PACKET" "$fact"
done

{
  echo "stage855_text_input_commit_inspection_surface_suite_version=1"
  echo "stage854_suite_packet=$STAGE854_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage855_text_input_commit_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage855 text input commit inspection surface suite: route_classification=text_input_commit_inspection_surface"
echo "cjgui stage855 text input commit inspection surface suite: suite_packet_path=$SUITE_PACKET"
