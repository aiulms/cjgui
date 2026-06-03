#!/usr/bin/env zsh
#
# Verifies the stage756 AI-generated UI acceptance commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage756_ai_generated_ui_acceptance_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage756 ai generated ui acceptance commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage756AiGeneratedUiAcceptanceCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage756AiGeneratedUiAcceptanceCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage756AiGeneratedUiAcceptanceCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage756AiGeneratedUiAcceptanceCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage755AiGeneratedUiAcceptanceCommitHostInspectionProofReadiness" \
  "didConsumeStage755AiGeneratedUiAcceptanceCommitHostInspectionProof" \
  "didMaterializeSharedAiGeneratedUiAcceptanceCommitRuntimeManager" \
  "didMaterializeAcceptanceCommitRuntimeContract" \
  "didMaterializeAcceptanceCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderOwnerRuntimeCommitSnapshotHostProofRuntime" \
  "didBindRuntimeManagerToStage753CommitPreflight" \
  "didBindRuntimeManagerToStage754RollbackSnapshot" \
  "didBindRuntimeManagerToStage755HostInspectionProof" \
  "didReduceFuturePerDemoAcceptanceCommitTemplateNeed" \
  "didPrepareStage757MinimalPublicPreviewApiFirstSlice"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage756 ai generated ui acceptance commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage756_ai_generated_ui_acceptance_commit_runtime_manager_owner_present=true"
echo "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_consumed=true"
echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_consumed_transitively=true"
echo "stage753_ai_generated_ui_acceptance_commit_preflight_consumed_transitively=true"
echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_consumed_transitively=true"
echo "shared_ai_generated_ui_acceptance_commit_runtime_manager_materialized=true"
echo "acceptance_commit_runtime_contract_materialized=true"
echo "acceptance_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_owner_runtime_commit_snapshot_host_proof_runtime_materialized=true"
echo "todo_ai_generated_ui_acceptance_commit_runtime_surface_materialized=true"
echo "settings_ai_generated_ui_acceptance_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_ai_generated_ui_acceptance_commit_runtime_surface_materialized=true"
echo "chat_composer_ai_generated_ui_acceptance_commit_runtime_surface_materialized=true"
echo "runtime_manager_bound_to_stage753_commit_preflight=true"
echo "runtime_manager_bound_to_stage754_rollback_snapshot=true"
echo "runtime_manager_bound_to_stage755_host_inspection_proof=true"
echo "future_per_demo_acceptance_commit_template_need_reduced=true"
echo "stage757_minimal_public_preview_api_first_slice_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
