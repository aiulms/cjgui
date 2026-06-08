#!/usr/bin/env zsh
#
# Focused suite for stage809. It consumes stage808 and records the acceptance rehearsal plan.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE809_TMPDIR:-/private/tmp/cjgui-stage809-stage812/stage809}"
SUITE_PACKET="$TMP_DIR/stage809-preview-component-api-state-store-commit-acceptance-rehearsal-suite.packet"
STAGE808_SUITE_PACKET="${CJGUI_STAGE809_INPUT_PACKET:-${CJGUI_STAGE808_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_REVIEW_HISTORY_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage805-stage808/stage808/stage808-preview-component-api-state-store-commit-review-history-runtime-manager-suite.packet}}"
STAGE808_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage808_preview_component_api_state_store_commit_review_history_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_owner.sh"
OWNER_LOG="$TMP_DIR/stage809-preview-component-api-state-store-commit-acceptance-rehearsal-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage809 preview component api state-store commit acceptance rehearsal suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE808_SUITE_PACKET" ]] || ! grep -F "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_suite_passed=true" "$STAGE808_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE808_TMPDIR="$TMP_DIR/stage808" zsh "$STAGE808_SUITE_SCRIPT" >/dev/null
  STAGE808_SUITE_PACKET="$TMP_DIR/stage808/stage808-preview-component-api-state-store-commit-review-history-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_consumed=true" \
  "acceptance_rehearsal_plan_materialized=true" \
  "acceptance_candidate_bundle_materialized=true" \
  "acceptance_policy_gate_ledger_materialized=true" \
  "rollback_anchor_bundle_materialized=true" \
  "non_committing_acceptance_evidence_bundle_materialized=true" \
  "acceptance_rehearsal_bound_to_review_history_runtime_manager=true" \
  "acceptance_rehearsal_non_committing=true" \
  "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_prepared=true" \
  "new_public_surface_added=false" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_suite_passed=true" \
  "shared_review_history_runtime_manager_materialized=true" \
  "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_prepared=true"; do
  require_file_fact "$STAGE808_SUITE_PACKET" "$fact"
done

{
  echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite_version=1"
  echo "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_suite_packet=$STAGE808_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage809 preview component api state-store commit acceptance rehearsal suite: route_classification=state_store_commit_acceptance_rehearsal"
echo "cjgui stage809 preview component api state-store commit acceptance rehearsal suite: suite_packet_path=$SUITE_PACKET"
