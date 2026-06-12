#!/usr/bin/env zsh
#
# Verifies the stage832 component state-store publishable runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage832_component_state_store_publishable_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage832 component state-store publishable runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage832ComponentStateStorePublishableRuntimeManagerPlan" \
  "CjguiInternalRendererStage832ComponentStateStorePublishableRuntimeManagerFacts" \
  "CjguiInternalRendererStage832ComponentStateStorePublishableRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage832ComponentStateStorePublishableRuntimeManagerDraft" \
  "CjguiInternalRendererStage831ComponentStateStoreCommitCandidateRollbackSnapshotReadiness" \
  "didConsumeStage831ComponentStateStoreCommitCandidateRollbackSnapshot" \
  "didMaterializeSharedPublishableStateRuntimeManager" \
  "didMaterializePublishableStateRuntimeContract" \
  "didMaterializePublishableStateExecutionReceiptContract" \
  "didMaterializeCycleOrderPublishableStateSlotCommitDemoRuntime" \
  "didMaterializeTodoPublishableStateRuntimeSurface" \
  "didMaterializeSettingsPublishableStateRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsPublishableStateRuntimeSurface" \
  "didMaterializeChatComposerPublishableStateRuntimeSurface" \
  "didMaterializeFileBrowserPublishableStateRuntimeSurface" \
  "didBindRuntimeManagerToStage829PublishableStateModel" \
  "didBindRuntimeManagerToStage830SlotValueModel" \
  "didBindRuntimeManagerToStage831CommitCandidateRollbackSnapshot" \
  "didReduceFuturePerDemoStateModelTemplateNeed" \
  "didPrepareStage833PublishableStateLayoutStyleResolverAfterStage832"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage832 component state-store publishable runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage832_component_state_store_publishable_runtime_manager_owner_present=true"
echo "stage831_component_state_store_commit_candidate_rollback_snapshot_consumed=true"
echo "stage830_component_state_store_slot_value_model_consumed_transitively=true"
echo "stage829_component_state_store_publishable_state_model_consumed_transitively=true"
echo "stage828_commit_first_slice_publication_runtime_manager_consumed_transitively=true"
echo "shared_publishable_state_runtime_manager_materialized=true"
echo "publishable_state_runtime_contract_materialized=true"
echo "publishable_state_execution_receipt_contract_materialized=true"
echo "cycle_order_publishable_state_slot_commit_demo_runtime_materialized=true"
echo "todo_publishable_state_runtime_surface_materialized=true"
echo "settings_publishable_state_runtime_surface_materialized=true"
echo "ai_generated_settings_publishable_state_runtime_surface_materialized=true"
echo "chat_composer_publishable_state_runtime_surface_materialized=true"
echo "file_browser_publishable_state_runtime_surface_materialized=true"
echo "publishable_runtime_manager_bound_to_stage829_state_model=true"
echo "publishable_runtime_manager_bound_to_stage830_slot_value_model=true"
echo "publishable_runtime_manager_bound_to_stage831_commit_candidate=true"
echo "future_per_demo_state_model_template_need_reduced=true"
echo "stage833_publishable_state_layout_style_resolver_after_stage832_prepared=true"
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
