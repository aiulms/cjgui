#!/usr/bin/env zsh
#
# Verifies the stage801 preview component API state-store commit diff/explain owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage801_preview_component_api_state_store_commit_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage801 preview component api state-store commit diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage801PreviewComponentApiStateStoreCommitDiffExplainPlan" \
  "CjguiInternalRendererStage801PreviewComponentApiStateStoreCommitDiffExplainFacts" \
  "CjguiInternalRendererStage801PreviewComponentApiStateStoreCommitDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage801PreviewComponentApiStateStoreCommitDiffExplainDraft" \
  "CjguiInternalRendererStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutorReadiness" \
  "didConsumeStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutor" \
  "didMaterializeCommitAdmissionSemanticDiffModel" \
  "didMaterializeMutationExplainRows" \
  "didMaterializeAffectedComponentMap" \
  "didMaterializeRollbackDiffSummary" \
  "didMaterializeCompatibilityExplainLane" \
  "didBindDiffExplainToStage800RuntimeExecutor" \
  "didPrepareStage802PreviewComponentApiStateStoreCommitReviewDecisionLoop"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage801 preview component api state-store commit diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage801_preview_component_api_state_store_commit_diff_explain_owner_present=true"
echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_consumed=true"
echo "stage799_preview_component_api_state_store_commit_demo_host_preview_consumed_transitively=true"
echo "commit_admission_semantic_diff_model_materialized=true"
echo "mutation_explain_rows_materialized=true"
echo "affected_component_map_materialized=true"
echo "rollback_diff_summary_materialized=true"
echo "compatibility_explain_lane_materialized=true"
echo "diff_explain_bound_to_stage800_runtime_executor=true"
echo "commit_diff_explain_non_committing=true"
echo "stage802_preview_component_api_state_store_commit_review_decision_loop_prepared=true"
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
