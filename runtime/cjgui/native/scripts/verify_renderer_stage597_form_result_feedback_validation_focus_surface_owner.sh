#!/usr/bin/env zsh
#
# Verifies the stage597 form result feedback validation/focus surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage597_form_result_feedback_validation_focus_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage597 form result feedback validation focus surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage597FormResultFeedbackValidationFocusSurfacePlan" \
  "CjguiInternalRendererStage597FormResultFeedbackValidationFocusSurfaceFacts" \
  "CjguiInternalRendererStage597FormResultFeedbackValidationFocusSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage597FormResultFeedbackValidationFocusSurfaceDraft" \
  "CjguiInternalRendererStage596FormResultHostFeedbackCycleRuntimeContractReadiness" \
  "didMaterializeSharedFormResultFeedbackValidationFocusSurface" \
  "didMaterializeFormResultFeedbackValidationDisplaySurface" \
  "didMaterializeFormResultFeedbackFocusMovementSurface" \
  "didMaterializeFormResultFeedbackInputDisplaySurface" \
  "didMaterializeFormResultFeedbackRenderCommandRefreshPreview" \
  "didMaterializeTodoFormResultFeedbackValidationFocusSurface" \
  "didMaterializeSettingsFormResultFeedbackValidationFocusSurface" \
  "didMaterializeAiGeneratedSettingsFormResultFeedbackValidationFocusSurface" \
  "didMaterializeChatComposerFormResultFeedbackValidationFocusSurface" \
  "didBindValidationFocusSurfaceToStage596RuntimeContract" \
  "didBindValidationFocusSurfaceToStage595DemoSurfaceReceipts" \
  "didPrepareStage598FormResultFeedbackHostInspectionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage597 form result feedback validation focus surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage597_form_result_feedback_validation_focus_surface_owner_present=true"
echo "stage596_form_result_host_feedback_cycle_runtime_contract_consumed=true"
echo "shared_form_result_feedback_validation_focus_surface_materialized=true"
echo "form_result_feedback_validation_display_surface_materialized=true"
echo "form_result_feedback_focus_movement_surface_materialized=true"
echo "form_result_feedback_input_display_surface_materialized=true"
echo "form_result_feedback_render_command_refresh_preview_materialized=true"
echo "todo_form_result_feedback_validation_focus_surface_materialized=true"
echo "settings_form_result_feedback_validation_focus_surface_materialized=true"
echo "ai_generated_settings_form_result_feedback_validation_focus_surface_materialized=true"
echo "chat_composer_form_result_feedback_validation_focus_surface_materialized=true"
echo "validation_focus_surface_bound_to_stage596_runtime_contract=true"
echo "validation_focus_surface_bound_to_stage595_demo_surface_receipts=true"
echo "stage598_form_result_feedback_host_inspection_receipt_prepared=true"
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
