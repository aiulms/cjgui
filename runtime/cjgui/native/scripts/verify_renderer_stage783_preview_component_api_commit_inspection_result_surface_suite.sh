#!/usr/bin/env zsh
#
# Focused suite for stage783. It consumes stage782 and verifies the result
# surface refresh / receipt for commit inspection review actions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE783_TMPDIR:-/private/tmp/cjgui-stage781-stage784/stage783}"
SUITE_PACKET="$TMP_DIR/stage783-preview-component-api-commit-inspection-result-surface-suite.packet"
STAGE782_SUITE_PACKET="${CJGUI_STAGE783_INPUT_PACKET:-${CJGUI_STAGE782_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_REVIEW_ACTIONS_SUITE_PACKET:-/private/tmp/cjgui-stage781-stage784/stage782/stage782-preview-component-api-commit-inspection-review-actions-suite.packet}}"
STAGE782_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage782_preview_component_api_commit_inspection_review_actions_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage783_preview_component_api_commit_inspection_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage783-preview-component-api-commit-inspection-result-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage783 preview component api commit inspection result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE782_SUITE_PACKET" ]] || ! grep -F "stage782_preview_component_api_commit_inspection_review_actions_suite_passed=true" "$STAGE782_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE782_TMPDIR="$TMP_DIR/stage782" zsh "$STAGE782_SUITE_SCRIPT" >/dev/null
  STAGE782_SUITE_PACKET="$TMP_DIR/stage782/stage782-preview-component-api-commit-inspection-review-actions-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage782_preview_component_api_commit_inspection_review_actions_consumed=true" \
  "commit_inspection_execution_receipt_materialized=true" \
  "commit_inspection_result_surface_refresh_materialized=true" \
  "commit_inspection_semantic_diff_receipt_materialized=true" \
  "commit_inspection_rollback_decision_preview_materialized=true" \
  "chat_composer_preview_component_api_commit_inspection_result_surface_materialized=true" \
  "result_surface_bound_to_stage782_review_actions=true" \
  "stage784_preview_component_api_commit_inspection_runtime_manager_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage782_preview_component_api_commit_inspection_review_actions_suite_passed=true" \
  "commit_inspection_acceptability_review_action_materialized=true" \
  "stage783_preview_component_api_commit_inspection_result_surface_prepared=true" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE782_SUITE_PACKET" "$fact"
done

{
  echo "stage783_preview_component_api_commit_inspection_result_surface_suite_version=1"
  echo "stage782_preview_component_api_commit_inspection_review_actions_suite_packet=$STAGE782_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage784_preview_component_api_commit_inspection_runtime_manager_after_stage783"
  echo "stage783_preview_component_api_commit_inspection_result_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage783 preview component api commit inspection result surface suite: route_classification=preview_api_commit_inspection_result_surface"
echo "cjgui stage783 preview component api commit inspection result surface suite: suite_packet_path=$SUITE_PACKET"
