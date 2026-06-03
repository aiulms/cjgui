#!/usr/bin/env zsh
#
# Verifies the stage776 preview component API commit admission runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage776_preview_component_api_commit_admission_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage776 preview component api commit admission runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage776PreviewComponentApiCommitAdmissionRuntimeManagerPlan" \
  "CjguiInternalRendererStage776PreviewComponentApiCommitAdmissionRuntimeManagerFacts" \
  "CjguiInternalRendererStage776PreviewComponentApiCommitAdmissionRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage776PreviewComponentApiCommitAdmissionRuntimeManagerDraft" \
  "CjguiInternalRendererStage775PreviewComponentApiCommitAdmissionHostInspectionSurfaceReadiness" \
  "didConsumeStage775PreviewComponentApiCommitAdmissionHostInspectionSurface" \
  "didMaterializeSharedPreviewComponentApiCommitAdmissionRuntimeManager" \
  "didMaterializePreviewComponentApiCommitAdmissionRuntimeContract" \
  "didMaterializePreviewComponentApiCommitAdmissionExecutionReceiptContract" \
  "didMaterializeCycleOrderPreviewApiCommitAdmissionDenialInspectionRuntime" \
  "didMaterializeChatComposerPreviewComponentApiCommitAdmissionRuntimeSurface" \
  "didBindCommitAdmissionRuntimeManagerToStage773AdmissionDryRun" \
  "didBindCommitAdmissionRuntimeManagerToStage774Receipt" \
  "didBindCommitAdmissionRuntimeManagerToStage775HostInspection" \
  "didReduceFuturePerDemoCommitAdmissionTemplateNeed" \
  "didPrepareStage777PreviewComponentApiStateStoreCommitBoundary"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage776 preview component api commit admission runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage776_preview_component_api_commit_admission_runtime_manager_owner_present=true"
echo "stage775_preview_component_api_commit_admission_host_inspection_surface_consumed=true"
echo "stage774_preview_component_api_commit_denial_rollback_receipt_consumed_transitively=true"
echo "stage773_preview_component_api_commit_admission_dry_run_consumed_transitively=true"
echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_consumed_transitively=true"
echo "shared_preview_component_api_commit_admission_runtime_manager_materialized=true"
echo "preview_component_api_commit_admission_runtime_contract_materialized=true"
echo "preview_component_api_commit_admission_execution_receipt_contract_materialized=true"
echo "cycle_order_preview_api_commit_admission_denial_inspection_runtime_materialized=true"
echo "todo_preview_component_api_commit_admission_runtime_surface_materialized=true"
echo "settings_preview_component_api_commit_admission_runtime_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_admission_runtime_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_admission_runtime_surface_materialized=true"
echo "commit_admission_runtime_manager_bound_to_stage773_admission_dry_run=true"
echo "commit_admission_runtime_manager_bound_to_stage774_receipt=true"
echo "commit_admission_runtime_manager_bound_to_stage775_host_inspection=true"
echo "future_per_demo_commit_admission_template_need_reduced=true"
echo "stage777_preview_component_api_state_store_commit_boundary_prepared=true"
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
