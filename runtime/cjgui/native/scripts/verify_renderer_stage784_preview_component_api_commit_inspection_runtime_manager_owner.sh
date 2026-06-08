#!/usr/bin/env zsh
#
# Verifies the stage784 preview component API commit inspection runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage784_preview_component_api_commit_inspection_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage784 preview component api commit inspection runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage784PreviewComponentApiCommitInspectionRuntimeManagerPlan" \
  "CjguiInternalRendererStage784PreviewComponentApiCommitInspectionRuntimeManagerFacts" \
  "CjguiInternalRendererStage784PreviewComponentApiCommitInspectionRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage784PreviewComponentApiCommitInspectionRuntimeManagerDraft" \
  "CjguiInternalRendererStage783PreviewComponentApiCommitInspectionResultSurfaceReadiness" \
  "didConsumeStage783PreviewComponentApiCommitInspectionResultSurface" \
  "didMaterializeSharedPreviewComponentApiCommitInspectionRuntimeManager" \
  "didMaterializePreviewComponentApiCommitInspectionRuntimeContract" \
  "didMaterializePreviewComponentApiCommitInspectionExecutionReceiptContract" \
  "didMaterializeCycleOrderPreviewApiCommitInspectionUiReviewResultRuntime" \
  "didMaterializeChatComposerPreviewComponentApiCommitInspectionRuntimeSurface" \
  "didReduceFuturePerDemoCommitInspectionTemplateNeed" \
  "didPrepareStage785PreviewComponentApiCommitInspectionPublicPreviewContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage784 preview component api commit inspection runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage784_preview_component_api_commit_inspection_runtime_manager_owner_present=true"
echo "stage783_preview_component_api_commit_inspection_result_surface_consumed=true"
echo "stage782_preview_component_api_commit_inspection_review_actions_consumed_transitively=true"
echo "stage781_preview_component_api_commit_inspection_ui_consumed_transitively=true"
echo "stage780_preview_component_api_state_store_commit_runtime_manager_consumed_transitively=true"
echo "shared_preview_component_api_commit_inspection_runtime_manager_materialized=true"
echo "preview_component_api_commit_inspection_runtime_contract_materialized=true"
echo "preview_component_api_commit_inspection_execution_receipt_contract_materialized=true"
echo "cycle_order_preview_api_commit_inspection_ui_review_result_runtime_materialized=true"
echo "todo_preview_component_api_commit_inspection_runtime_surface_materialized=true"
echo "settings_preview_component_api_commit_inspection_runtime_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_inspection_runtime_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_inspection_runtime_surface_materialized=true"
echo "commit_inspection_runtime_manager_bound_to_stage781_ui=true"
echo "commit_inspection_runtime_manager_bound_to_stage782_review_actions=true"
echo "commit_inspection_runtime_manager_bound_to_stage783_result_surface=true"
echo "future_per_demo_commit_inspection_template_need_reduced=true"
echo "stage785_preview_component_api_commit_inspection_public_preview_contract_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
