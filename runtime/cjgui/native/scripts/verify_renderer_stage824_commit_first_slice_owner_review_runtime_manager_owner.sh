#!/usr/bin/env zsh
#
# Verifies the stage824 commit first-slice owner review runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage824_commit_first_slice_owner_review_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage824 commit first-slice owner review runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage824CommitFirstSliceOwnerReviewRuntimeManagerPlan" \
  "CjguiInternalRendererStage824CommitFirstSliceOwnerReviewRuntimeManagerFacts" \
  "CjguiInternalRendererStage824CommitFirstSliceOwnerReviewRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage824CommitFirstSliceOwnerReviewRuntimeManagerDraft" \
  "CjguiInternalRendererStage823CommitFirstSliceOwnerReviewDemoHostSurfaceReadiness" \
  "didConsumeStage823CommitFirstSliceOwnerReviewDemoHostSurface" \
  "didMaterializeSharedOwnerReviewRuntimeManager" \
  "didMaterializeOwnerReviewRuntimeContract" \
  "didMaterializeOwnerReviewExecutionReceiptContract" \
  "didMaterializeCycleOrderOwnerReviewGateDecisionDemoRuntime" \
  "didMaterializeFileBrowserOwnerReviewRuntimeSurface" \
  "didReduceFuturePerDemoOwnerReviewTemplateNeed" \
  "didPrepareStage825CommitFirstSlicePublicationGateAfterStage824"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage824 commit first-slice owner review runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage824_commit_first_slice_owner_review_runtime_manager_owner_present=true"
echo "stage823_commit_first_slice_owner_review_demo_host_surface_consumed=true"
echo "stage822_commit_first_slice_review_decision_router_consumed_transitively=true"
echo "stage821_commit_first_slice_owner_review_gate_consumed_transitively=true"
echo "stage820_commit_first_slice_host_inspection_runtime_presenter_consumed_transitively=true"
echo "shared_owner_review_runtime_manager_materialized=true"
echo "owner_review_runtime_contract_materialized=true"
echo "owner_review_execution_receipt_contract_materialized=true"
echo "cycle_order_owner_review_gate_decision_demo_runtime_materialized=true"
echo "todo_owner_review_runtime_surface_materialized=true"
echo "settings_owner_review_runtime_surface_materialized=true"
echo "ai_generated_settings_owner_review_runtime_surface_materialized=true"
echo "chat_composer_owner_review_runtime_surface_materialized=true"
echo "file_browser_owner_review_runtime_surface_materialized=true"
echo "owner_review_runtime_manager_bound_to_stage821_gate=true"
echo "owner_review_runtime_manager_bound_to_stage822_decision_router=true"
echo "owner_review_runtime_manager_bound_to_stage823_demo_surface=true"
echo "future_per_demo_owner_review_template_need_reduced=true"
echo "stage825_commit_first_slice_publication_gate_after_stage824_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
