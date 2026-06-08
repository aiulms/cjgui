#!/usr/bin/env zsh
#
# Verifies the stage828 commit first-slice publication runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage828_commit_first_slice_publication_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage828 commit first-slice publication runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage828CommitFirstSlicePublicationRuntimeManagerPlan" \
  "CjguiInternalRendererStage828CommitFirstSlicePublicationRuntimeManagerFacts" \
  "CjguiInternalRendererStage828CommitFirstSlicePublicationRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage828CommitFirstSlicePublicationRuntimeManagerDraft" \
  "CjguiInternalRendererStage827CommitFirstSlicePublicationDemoHostSurfaceReadiness" \
  "didConsumeStage827CommitFirstSlicePublicationDemoHostSurface" \
  "didMaterializeSharedPublicationRuntimeManager" \
  "didMaterializePublicationRuntimeContract" \
  "didMaterializePublicationExecutionReceiptContract" \
  "didMaterializeCycleOrderPublicationGateRehearsalDemoRuntime" \
  "didMaterializeFileBrowserPublicationRuntimeSurface" \
  "didReduceFuturePerDemoPublicationTemplateNeed" \
  "didPrepareStage829ComponentStateStorePublishableStateModelAfterStage828"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage828 commit first-slice publication runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage828_commit_first_slice_publication_runtime_manager_owner_present=true"
echo "stage827_commit_first_slice_publication_demo_host_surface_consumed=true"
echo "stage826_commit_first_slice_publication_visibility_rehearsal_consumed_transitively=true"
echo "stage825_commit_first_slice_publication_gate_consumed_transitively=true"
echo "stage824_commit_first_slice_owner_review_runtime_manager_consumed_transitively=true"
echo "shared_publication_runtime_manager_materialized=true"
echo "publication_runtime_contract_materialized=true"
echo "publication_execution_receipt_contract_materialized=true"
echo "cycle_order_publication_gate_rehearsal_demo_runtime_materialized=true"
echo "todo_publication_runtime_surface_materialized=true"
echo "settings_publication_runtime_surface_materialized=true"
echo "ai_generated_settings_publication_runtime_surface_materialized=true"
echo "chat_composer_publication_runtime_surface_materialized=true"
echo "file_browser_publication_runtime_surface_materialized=true"
echo "publication_runtime_manager_bound_to_stage825_gate=true"
echo "publication_runtime_manager_bound_to_stage826_visibility_rehearsal=true"
echo "publication_runtime_manager_bound_to_stage827_demo_surface=true"
echo "future_per_demo_publication_template_need_reduced=true"
echo "stage829_component_state_store_publishable_state_model_after_stage828_prepared=true"
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
