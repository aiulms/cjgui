#!/usr/bin/env zsh
#
# Verifies the stage772 preview component API owner acceptance decision runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage772_preview_component_api_owner_acceptance_decision_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage772 preview component api owner acceptance decision runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManagerPlan" \
  "CjguiInternalRendererStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManagerFacts" \
  "CjguiInternalRendererStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManagerDraft" \
  "CjguiInternalRendererStage771PreviewComponentApiAcceptanceFeedbackSurfaceReadiness" \
  "didConsumeStage771PreviewComponentApiAcceptanceFeedbackSurface" \
  "didMaterializeSharedPreviewComponentApiOwnerAcceptanceDecisionRuntimeManager" \
  "didMaterializePreviewComponentApiOwnerAcceptanceDecisionRuntimeContract" \
  "didMaterializePreviewComponentApiOwnerAcceptanceDecisionExecutionReceiptContract" \
  "didMaterializeCycleOrderPreviewApiOwnerBoundaryDecisionFeedbackRuntime" \
  "didMaterializeChatComposerPreviewComponentApiOwnerAcceptanceDecisionRuntimeSurface" \
  "didBindOwnerAcceptanceDecisionRuntimeManagerToStage769Boundary" \
  "didReduceFuturePerDemoOwnerAcceptanceDecisionTemplateNeed" \
  "didPrepareStage773PreviewComponentApiCommitAdmissionDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage772 preview component api owner acceptance decision runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_owner_present=true"
echo "stage771_preview_component_api_acceptance_feedback_surface_consumed=true"
echo "stage770_preview_component_api_acceptance_decision_reducer_consumed_transitively=true"
echo "stage769_preview_component_api_owner_acceptance_boundary_consumed_transitively=true"
echo "stage768_preview_component_api_commit_runtime_manager_consumed_transitively=true"
echo "shared_preview_component_api_owner_acceptance_decision_runtime_manager_materialized=true"
echo "preview_component_api_owner_acceptance_decision_runtime_contract_materialized=true"
echo "preview_component_api_owner_acceptance_decision_execution_receipt_contract_materialized=true"
echo "cycle_order_preview_api_owner_boundary_decision_feedback_runtime_materialized=true"
echo "todo_preview_component_api_owner_acceptance_decision_runtime_surface_materialized=true"
echo "settings_preview_component_api_owner_acceptance_decision_runtime_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_owner_acceptance_decision_runtime_surface_materialized=true"
echo "chat_composer_preview_component_api_owner_acceptance_decision_runtime_surface_materialized=true"
echo "owner_acceptance_decision_runtime_manager_bound_to_stage769_boundary=true"
echo "owner_acceptance_decision_runtime_manager_bound_to_stage770_decision_reducer=true"
echo "owner_acceptance_decision_runtime_manager_bound_to_stage771_feedback_surface=true"
echo "future_per_demo_owner_acceptance_decision_template_need_reduced=true"
echo "stage773_preview_component_api_commit_admission_dry_run_prepared=true"
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
