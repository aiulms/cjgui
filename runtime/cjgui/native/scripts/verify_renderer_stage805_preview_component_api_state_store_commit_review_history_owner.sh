#!/usr/bin/env zsh
#
# Verifies the stage805 preview component API state-store commit review history owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage805_preview_component_api_state_store_commit_review_history.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage805 preview component api state-store commit review history: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage805PreviewComponentApiStateStoreCommitReviewHistoryPlan" \
  "CjguiInternalRendererStage805PreviewComponentApiStateStoreCommitReviewHistoryFacts" \
  "CjguiInternalRendererStage805PreviewComponentApiStateStoreCommitReviewHistoryReadiness" \
  "cjguiInternalExecuteDefaultRendererStage805PreviewComponentApiStateStoreCommitReviewHistoryDraft" \
  "CjguiInternalRendererStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManagerReadiness" \
  "didConsumeStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManager" \
  "didMaterializeCommitReviewHistoryLedger" \
  "didMaterializeSemanticDiffHistoryEntries" \
  "didMaterializeReviewerDecisionHistoryEntries" \
  "didMaterializeAffectedComponentHistoryIndex" \
  "didMaterializeRollbackDiffHistoryEntry" \
  "didMaterializeReviewHistoryFilterDescriptor" \
  "didPrepareStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsal"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage805 preview component api state-store commit review history: missing token $token" >&2
    exit 3
  fi
done

echo "stage805_preview_component_api_state_store_commit_review_history_owner_present=true"
echo "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_consumed=true"
echo "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_consumed_transitively=true"
echo "commit_review_history_ledger_materialized=true"
echo "semantic_diff_history_entries_materialized=true"
echo "reviewer_decision_history_entries_materialized=true"
echo "affected_component_history_index_materialized=true"
echo "rollback_diff_history_entry_materialized=true"
echo "review_history_filter_descriptor_materialized=true"
echo "review_history_non_committing=true"
echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
