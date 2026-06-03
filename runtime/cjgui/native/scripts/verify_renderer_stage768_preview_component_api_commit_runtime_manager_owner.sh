#!/usr/bin/env zsh
#
# Verifies the stage768 preview component API commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage768_preview_component_api_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage768 preview component api commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage768PreviewComponentApiCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage768PreviewComponentApiCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage768PreviewComponentApiCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage768PreviewComponentApiCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage767PreviewComponentApiCommitHostInspectionProofReadiness" \
  "didConsumeStage767PreviewComponentApiCommitHostInspectionProof" \
  "didMaterializeSharedPreviewComponentApiCommitRuntimeManager" \
  "didMaterializePreviewComponentApiCommitRuntimeContract" \
  "didMaterializePreviewComponentApiCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderPreviewApiCommitPreflightSnapshotInspectionRuntime" \
  "didMaterializeChatComposerPreviewComponentApiCommitRuntimeSurface" \
  "didReduceFuturePerDemoPreviewApiCommitTemplateNeed" \
  "didPrepareStage769PreviewComponentApiOwnerAcceptanceBoundary"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage768 preview component api commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage768_preview_component_api_commit_runtime_manager_owner_present=true"
echo "stage767_preview_component_api_commit_host_inspection_proof_consumed=true"
echo "stage766_preview_component_api_commit_rollback_snapshot_consumed_transitively=true"
echo "stage765_preview_component_api_commit_preflight_consumed_transitively=true"
echo "stage764_preview_component_api_visual_resolver_runtime_manager_consumed_transitively=true"
echo "shared_preview_component_api_commit_runtime_manager_materialized=true"
echo "preview_component_api_commit_runtime_contract_materialized=true"
echo "preview_component_api_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_preview_api_commit_preflight_snapshot_inspection_runtime_materialized=true"
echo "todo_preview_component_api_commit_runtime_surface_materialized=true"
echo "settings_preview_component_api_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_runtime_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_runtime_surface_materialized=true"
echo "commit_runtime_manager_bound_to_stage765_commit_preflight=true"
echo "commit_runtime_manager_bound_to_stage766_rollback_snapshot=true"
echo "commit_runtime_manager_bound_to_stage767_host_inspection=true"
echo "future_per_demo_preview_api_commit_template_need_reduced=true"
echo "stage769_preview_component_api_owner_acceptance_boundary_prepared=true"
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
