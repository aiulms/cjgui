#!/usr/bin/env zsh
#
# Focused suite for stage782. It consumes stage781 and verifies non-dispatching
# review actions for the commit inspection UI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE782_TMPDIR:-/private/tmp/cjgui-stage781-stage784/stage782}"
SUITE_PACKET="$TMP_DIR/stage782-preview-component-api-commit-inspection-review-actions-suite.packet"
STAGE781_SUITE_PACKET="${CJGUI_STAGE782_INPUT_PACKET:-${CJGUI_STAGE781_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_UI_SUITE_PACKET:-/private/tmp/cjgui-stage781-stage784/stage781/stage781-preview-component-api-commit-inspection-ui-suite.packet}}"
STAGE781_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage781_preview_component_api_commit_inspection_ui_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage782_preview_component_api_commit_inspection_review_actions_owner.sh"
OWNER_LOG="$TMP_DIR/stage782-preview-component-api-commit-inspection-review-actions-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage782 preview component api commit inspection review actions suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE781_SUITE_PACKET" ]] || ! grep -F "stage781_preview_component_api_commit_inspection_ui_suite_passed=true" "$STAGE781_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE781_TMPDIR="$TMP_DIR/stage781" zsh "$STAGE781_SUITE_SCRIPT" >/dev/null
  STAGE781_SUITE_PACKET="$TMP_DIR/stage781/stage781-preview-component-api-commit-inspection-ui-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage781_preview_component_api_commit_inspection_ui_consumed=true" \
  "commit_inspection_diff_acknowledge_action_materialized=true" \
  "commit_inspection_rollback_select_action_materialized=true" \
  "commit_inspection_acceptability_review_action_materialized=true" \
  "commit_inspection_reject_reason_draft_action_materialized=true" \
  "chat_composer_preview_component_api_commit_inspection_review_action_surface_materialized=true" \
  "review_actions_bound_to_stage781_inspection_ui=true" \
  "stage783_preview_component_api_commit_inspection_result_surface_prepared=true" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage781_preview_component_api_commit_inspection_ui_suite_passed=true" \
  "commit_inspection_ui_row_model_materialized=true" \
  "stage782_preview_component_api_commit_inspection_review_actions_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE781_SUITE_PACKET" "$fact"
done

{
  echo "stage782_preview_component_api_commit_inspection_review_actions_suite_version=1"
  echo "stage781_preview_component_api_commit_inspection_ui_suite_packet=$STAGE781_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage783_preview_component_api_commit_inspection_result_surface_after_stage782"
  echo "stage782_preview_component_api_commit_inspection_review_actions_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage782 preview component api commit inspection review actions suite: route_classification=preview_api_commit_inspection_review_actions"
echo "cjgui stage782 preview component api commit inspection review actions suite: suite_packet_path=$SUITE_PACKET"
