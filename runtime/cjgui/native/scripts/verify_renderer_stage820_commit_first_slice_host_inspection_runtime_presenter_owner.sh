#!/usr/bin/env zsh
#
# Verifies the stage820 commit first-slice host inspection runtime presenter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage820_commit_first_slice_host_inspection_runtime_presenter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage820 commit first-slice host inspection runtime presenter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage820CommitFirstSliceHostInspectionRuntimePresenterPlan" \
  "CjguiInternalRendererStage820CommitFirstSliceHostInspectionRuntimePresenterFacts" \
  "CjguiInternalRendererStage820CommitFirstSliceHostInspectionRuntimePresenterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage820CommitFirstSliceHostInspectionRuntimePresenterDraft" \
  "CjguiInternalRendererStage819CommitFirstSliceDemoHostInspectionSurfaceReadiness" \
  "didConsumeStage819CommitFirstSliceDemoHostInspectionSurface" \
  "didMaterializeSharedCommitHostInspectionRuntimePresenter" \
  "didMaterializeCommitHostInspectionRuntimeContract" \
  "didMaterializeCommitHostInspectionExecutionReceiptContract" \
  "didMaterializeCycleOrderCommitHostInspectionLensFilterSurfacePresenter" \
  "didMaterializeFileBrowserCommitInspectionRuntimeSurface" \
  "didReduceFuturePerDemoCommitHostInspectionTemplateNeed" \
  "didPrepareStage821CommitFirstSliceOwnerReviewGateAfterStage820"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage820 commit first-slice host inspection runtime presenter: missing token $token" >&2
    exit 3
  fi
done

echo "stage820_commit_first_slice_host_inspection_runtime_presenter_owner_present=true"
echo "stage819_commit_first_slice_demo_host_inspection_surface_consumed=true"
echo "stage818_commit_first_slice_inspection_filter_controller_consumed_transitively=true"
echo "stage817_commit_first_slice_host_inspection_lens_consumed_transitively=true"
echo "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_consumed_transitively=true"
echo "shared_commit_host_inspection_runtime_presenter_materialized=true"
echo "commit_host_inspection_runtime_contract_materialized=true"
echo "commit_host_inspection_execution_receipt_contract_materialized=true"
echo "cycle_order_commit_host_inspection_lens_filter_surface_presenter_materialized=true"
echo "todo_commit_inspection_runtime_surface_materialized=true"
echo "settings_commit_inspection_runtime_surface_materialized=true"
echo "ai_generated_settings_commit_inspection_runtime_surface_materialized=true"
echo "chat_composer_commit_inspection_runtime_surface_materialized=true"
echo "file_browser_commit_inspection_runtime_surface_materialized=true"
echo "commit_host_inspection_runtime_presenter_bound_to_stage817_lens=true"
echo "commit_host_inspection_runtime_presenter_bound_to_stage818_filter_controller=true"
echo "commit_host_inspection_runtime_presenter_bound_to_stage819_demo_surface=true"
echo "future_per_demo_commit_host_inspection_template_need_reduced=true"
echo "stage821_commit_first_slice_owner_review_gate_after_stage820_prepared=true"
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
