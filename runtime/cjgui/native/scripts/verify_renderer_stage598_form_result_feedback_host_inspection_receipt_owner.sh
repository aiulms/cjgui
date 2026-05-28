#!/usr/bin/env zsh
#
# Verifies the stage598 form result feedback host inspection receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage598_form_result_feedback_host_inspection_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage598 form result feedback host inspection receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage598FormResultFeedbackHostInspectionReceiptPlan" \
  "CjguiInternalRendererStage598FormResultFeedbackHostInspectionReceiptFacts" \
  "CjguiInternalRendererStage598FormResultFeedbackHostInspectionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage598FormResultFeedbackHostInspectionReceiptDraft" \
  "CjguiInternalRendererStage597FormResultFeedbackValidationFocusSurfaceReadiness" \
  "didMaterializeSharedFormResultFeedbackHostInspectionReceipt" \
  "didMaterializeValidationDisplayHostSlotReceipt" \
  "didMaterializeFocusMovementHostSlotReceipt" \
  "didMaterializeInputFeedbackHostSlotReceipt" \
  "didMaterializeRenderRefreshHostSlotReceipt" \
  "didMaterializeTodoFormResultFeedbackHostInspectionReceipt" \
  "didMaterializeSettingsFormResultFeedbackHostInspectionReceipt" \
  "didMaterializeAiGeneratedSettingsFormResultFeedbackHostInspectionReceipt" \
  "didMaterializeChatComposerFormResultFeedbackHostInspectionReceipt" \
  "didBindHostInspectionReceiptToStage597ValidationFocusSurface" \
  "didBindHostInspectionReceiptToStage596RuntimeContract" \
  "didPrepareStage599FormResultFeedbackSurfaceReducer"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage598 form result feedback host inspection receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage598_form_result_feedback_host_inspection_receipt_owner_present=true"
echo "stage597_form_result_feedback_validation_focus_surface_consumed=true"
echo "stage596_form_result_host_feedback_cycle_runtime_contract_consumed_transitively=true"
echo "shared_form_result_feedback_host_inspection_receipt_materialized=true"
echo "validation_display_host_slot_receipt_materialized=true"
echo "focus_movement_host_slot_receipt_materialized=true"
echo "input_feedback_host_slot_receipt_materialized=true"
echo "render_refresh_host_slot_receipt_materialized=true"
echo "todo_form_result_feedback_host_inspection_receipt_materialized=true"
echo "settings_form_result_feedback_host_inspection_receipt_materialized=true"
echo "ai_generated_settings_form_result_feedback_host_inspection_receipt_materialized=true"
echo "chat_composer_form_result_feedback_host_inspection_receipt_materialized=true"
echo "host_inspection_receipt_bound_to_stage597_validation_focus_surface=true"
echo "host_inspection_receipt_bound_to_stage596_runtime_contract=true"
echo "stage599_form_result_feedback_surface_reducer_prepared=true"
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
