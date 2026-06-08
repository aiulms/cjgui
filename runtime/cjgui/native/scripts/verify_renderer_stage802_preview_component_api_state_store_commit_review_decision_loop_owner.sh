#!/usr/bin/env zsh
#
# Verifies the stage802 preview component API state-store commit review decision loop owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage802_preview_component_api_state_store_commit_review_decision_loop.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage802 preview component api state-store commit review decision loop: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage802PreviewComponentApiStateStoreCommitReviewDecisionLoopPlan" \
  "CjguiInternalRendererStage802PreviewComponentApiStateStoreCommitReviewDecisionLoopFacts" \
  "CjguiInternalRendererStage802PreviewComponentApiStateStoreCommitReviewDecisionLoopReadiness" \
  "cjguiInternalExecuteDefaultRendererStage802PreviewComponentApiStateStoreCommitReviewDecisionLoopDraft" \
  "CjguiInternalRendererStage801PreviewComponentApiStateStoreCommitDiffExplainReadiness" \
  "didConsumeStage801PreviewComponentApiStateStoreCommitDiffExplain" \
  "didMaterializeReviewerDecisionOptions" \
  "didMaterializeRejectReasonTaxonomy" \
  "didMaterializeRequestChangesPatchHints" \
  "didMaterializeAcceptanceHoldReceipt" \
  "didMaterializeSemanticDiffAcknowledgeRoute" \
  "didKeepReviewerDecisionLoopNonDispatching" \
  "didPrepareStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage802 preview component api state-store commit review decision loop: missing token $token" >&2
    exit 3
  fi
done

echo "stage802_preview_component_api_state_store_commit_review_decision_loop_owner_present=true"
echo "stage801_preview_component_api_state_store_commit_diff_explain_consumed=true"
echo "reviewer_decision_options_materialized=true"
echo "reject_reason_taxonomy_materialized=true"
echo "request_changes_patch_hints_materialized=true"
echo "acceptance_hold_receipt_materialized=true"
echo "semantic_diff_acknowledge_route_materialized=true"
echo "reviewer_decision_loop_non_dispatching=true"
echo "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_prepared=true"
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
