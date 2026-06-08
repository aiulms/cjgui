#!/usr/bin/env zsh
#
# Focused suite for stage805. It consumes stage804 and records the review history ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE805_TMPDIR:-/private/tmp/cjgui-stage805-stage808/stage805}"
SUITE_PACKET="$TMP_DIR/stage805-preview-component-api-state-store-commit-review-history-suite.packet"
STAGE804_SUITE_PACKET="${CJGUI_STAGE805_INPUT_PACKET:-${CJGUI_STAGE804_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_DIFF_EXPLAIN_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage805-stage808/stage804/stage804-preview-component-api-state-store-commit-diff-explain-runtime-manager-suite.packet}}"
STAGE804_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_owner.sh"
OWNER_LOG="$TMP_DIR/stage805-preview-component-api-state-store-commit-review-history-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage805 preview component api state-store commit review history suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE804_SUITE_PACKET" ]] || ! grep -F "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_suite_passed=true" "$STAGE804_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE804_TMPDIR="$TMP_DIR/stage804" zsh "$STAGE804_SUITE_SCRIPT" >/dev/null
  STAGE804_SUITE_PACKET="$TMP_DIR/stage804/stage804-preview-component-api-state-store-commit-diff-explain-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage805_preview_component_api_state_store_commit_review_history_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_consumed=true" \
  "commit_review_history_ledger_materialized=true" \
  "semantic_diff_history_entries_materialized=true" \
  "reviewer_decision_history_entries_materialized=true" \
  "affected_component_history_index_materialized=true" \
  "rollback_diff_history_entry_materialized=true" \
  "review_history_filter_descriptor_materialized=true" \
  "review_history_non_committing=true" \
  "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_prepared=true" \
  "new_public_surface_added=false" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_suite_passed=true" \
  "shared_diff_explain_review_runtime_manager_materialized=true" \
  "stage805_preview_component_api_state_store_commit_diff_explain_review_history_prepared=true"; do
  require_file_fact "$STAGE804_SUITE_PACKET" "$fact"
done

{
  echo "stage805_preview_component_api_state_store_commit_review_history_suite_version=1"
  echo "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_suite_packet=$STAGE804_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage805_preview_component_api_state_store_commit_review_history_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage805 preview component api state-store commit review history suite: route_classification=state_store_commit_review_history"
echo "cjgui stage805 preview component api state-store commit review history suite: suite_packet_path=$SUITE_PACKET"
