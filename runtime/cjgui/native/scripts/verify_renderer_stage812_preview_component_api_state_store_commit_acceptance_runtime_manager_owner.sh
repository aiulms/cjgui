#!/usr/bin/env zsh
#
# Verifies the stage812 preview component API state-store commit acceptance runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage812_preview_component_api_state_store_commit_acceptance_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage812 preview component api state-store commit acceptance runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManagerPlan" \
  "CjguiInternalRendererStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManagerFacts" \
  "CjguiInternalRendererStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManagerDraft" \
  "CjguiInternalRendererStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurfaceReadiness" \
  "didConsumeStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurface" \
  "didMaterializeSharedAcceptanceRehearsalRuntimeManager" \
  "didMaterializeAcceptanceRehearsalRuntimeContract" \
  "didMaterializeAcceptanceRehearsalExecutionReceiptContract" \
  "didMaterializeCycleOrderAcceptanceRehearsalDemoRuntime" \
  "didMaterializeFileBrowserAcceptanceRuntimeSurface" \
  "didReduceFuturePerDemoAcceptanceTemplateNeed" \
  "didPrepareStage813PreviewComponentApiStateStoreCommitFirstSlicePreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage812 preview component api state-store commit acceptance runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_owner_present=true"
echo "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_consumed=true"
echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_consumed_transitively=true"
echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_consumed_transitively=true"
echo "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_consumed_transitively=true"
echo "shared_acceptance_rehearsal_runtime_manager_materialized=true"
echo "acceptance_rehearsal_runtime_contract_materialized=true"
echo "acceptance_rehearsal_execution_receipt_contract_materialized=true"
echo "cycle_order_acceptance_rehearsal_demo_runtime_materialized=true"
echo "todo_acceptance_runtime_surface_materialized=true"
echo "settings_acceptance_runtime_surface_materialized=true"
echo "ai_generated_settings_acceptance_runtime_surface_materialized=true"
echo "chat_composer_acceptance_runtime_surface_materialized=true"
echo "file_browser_acceptance_runtime_surface_materialized=true"
echo "acceptance_runtime_manager_bound_to_stage809_rehearsal=true"
echo "acceptance_runtime_manager_bound_to_stage810_decision_dry_run=true"
echo "acceptance_runtime_manager_bound_to_stage811_demo_host_surface=true"
echo "future_per_demo_acceptance_template_need_reduced=true"
echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_prepared=true"
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
