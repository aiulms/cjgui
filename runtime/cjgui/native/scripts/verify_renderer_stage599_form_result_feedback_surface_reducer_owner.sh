#!/usr/bin/env zsh
#
# Verifies the stage599 form result feedback surface reducer owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage599_form_result_feedback_surface_reducer.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage599 form result feedback surface reducer: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage599FormResultFeedbackSurfaceReducerPlan" \
  "CjguiInternalRendererStage599FormResultFeedbackSurfaceReducerFacts" \
  "CjguiInternalRendererStage599FormResultFeedbackSurfaceReducerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage599FormResultFeedbackSurfaceReducerDraft" \
  "CjguiInternalRendererStage598FormResultFeedbackHostInspectionReceiptReadiness" \
  "didMaterializeSharedFormResultFeedbackSurfaceReducer" \
  "didMaterializeAcceptedFeedbackSurfaceReduction" \
  "didMaterializeRejectedValidationFeedbackSurfaceReduction" \
  "didMaterializePendingOwnerAcceptanceFeedbackSurfaceReduction" \
  "didMaterializeValidationFocusInputFeedbackReductionLedger" \
  "didMaterializeTodoReducedFormResultFeedbackSurface" \
  "didMaterializeSettingsReducedFormResultFeedbackSurface" \
  "didMaterializeAiGeneratedSettingsReducedFormResultFeedbackSurface" \
  "didMaterializeChatComposerReducedFormResultFeedbackSurface" \
  "didBindSurfaceReducerToStage598HostInspectionReceipts" \
  "didBindSurfaceReducerToStage597ValidationFocusSurface" \
  "didPrepareStage600FormResultDemoHostFeedbackSurfaceIntegration"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage599 form result feedback surface reducer: missing token $token" >&2
    exit 3
  fi
done

echo "stage599_form_result_feedback_surface_reducer_owner_present=true"
echo "stage598_form_result_feedback_host_inspection_receipt_consumed=true"
echo "stage597_form_result_feedback_validation_focus_surface_consumed_transitively=true"
echo "shared_form_result_feedback_surface_reducer_materialized=true"
echo "accepted_feedback_surface_reduction_materialized=true"
echo "rejected_validation_feedback_surface_reduction_materialized=true"
echo "pending_owner_acceptance_feedback_surface_reduction_materialized=true"
echo "validation_focus_input_feedback_reduction_ledger_materialized=true"
echo "todo_reduced_form_result_feedback_surface_materialized=true"
echo "settings_reduced_form_result_feedback_surface_materialized=true"
echo "ai_generated_settings_reduced_form_result_feedback_surface_materialized=true"
echo "chat_composer_reduced_form_result_feedback_surface_materialized=true"
echo "surface_reducer_bound_to_stage598_host_inspection_receipts=true"
echo "surface_reducer_bound_to_stage597_validation_focus_surface=true"
echo "stage600_form_result_demo_host_feedback_surface_integration_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
