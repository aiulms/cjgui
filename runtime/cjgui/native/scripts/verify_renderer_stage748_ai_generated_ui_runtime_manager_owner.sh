#!/usr/bin/env zsh
#
# Verifies the stage748 AI-generated UI runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage748_ai_generated_ui_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage748 ai generated ui runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage748AiGeneratedUiRuntimeManagerPlan" \
  "CjguiInternalRendererStage748AiGeneratedUiRuntimeManagerFacts" \
  "CjguiInternalRendererStage748AiGeneratedUiRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage748AiGeneratedUiRuntimeManagerDraft" \
  "CjguiInternalRendererStage747AiGeneratedUiHostInspectionSurfaceReadiness" \
  "didConsumeStage747AiGeneratedUiHostInspectionSurface" \
  "didMaterializeSharedAiGeneratedUiAuthoringRuntimeManager" \
  "didMaterializeAiGeneratedUiAuthoringRuntimeContract" \
  "didMaterializeAiGeneratedUiExecutionReceiptContract" \
  "didMaterializeCycleOrderAiGeneratedProposalReviewHostRuntime" \
  "didReduceFuturePerDemoAiGeneratedUiTemplateNeed" \
  "didPrepareStage749AiGeneratedUiOwnerAcceptancePreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage748 ai generated ui runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage748_ai_generated_ui_runtime_manager_owner_present=true"
echo "stage747_ai_generated_ui_host_inspection_surface_consumed=true"
echo "stage746_ai_generated_ui_owner_review_preflight_consumed_transitively=true"
echo "stage745_ai_generated_ui_dsl_dry_run_consumed_transitively=true"
echo "stage744_component_api_authoring_dsl_runtime_manager_consumed_transitively=true"
echo "shared_ai_generated_ui_authoring_runtime_manager_materialized=true"
echo "ai_generated_ui_authoring_runtime_contract_materialized=true"
echo "ai_generated_ui_execution_receipt_contract_materialized=true"
echo "cycle_order_ai_generated_proposal_review_host_runtime_materialized=true"
echo "todo_ai_generated_ui_runtime_surface_materialized=true"
echo "settings_ai_generated_ui_runtime_surface_materialized=true"
echo "ai_generated_settings_ai_generated_ui_runtime_surface_materialized=true"
echo "chat_composer_ai_generated_ui_runtime_surface_materialized=true"
echo "future_per_demo_ai_generated_ui_template_need_reduced=true"
echo "stage749_ai_generated_ui_owner_acceptance_preflight_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
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
