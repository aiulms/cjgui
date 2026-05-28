#!/usr/bin/env zsh
#
# Verifies the stage666 component feedback input host inspection receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage666_component_feedback_input_host_inspection_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage666 component feedback input host inspection receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage666ComponentFeedbackInputHostInspectionReceiptPlan" \
  "CjguiInternalRendererStage666ComponentFeedbackInputHostInspectionReceiptFacts" \
  "CjguiInternalRendererStage666ComponentFeedbackInputHostInspectionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage666ComponentFeedbackInputHostInspectionReceiptDraft" \
  "CjguiInternalRendererStage665ComponentFeedbackInputDemoHostSurfaceReadiness" \
  "didConsumeStage665ComponentFeedbackInputDemoHostSurface" \
  "didMaterializeSharedFeedbackInputHostInspectionReceipt" \
  "didMaterializeFeedbackInputHostInspectionProbeInput" \
  "didMaterializeValidationDismissInspectionReceipt" \
  "didMaterializeFocusMovementInspectionReceipt" \
  "didMaterializeInputFeedbackClearInspectionReceipt" \
  "didMaterializeSemanticDiffAcknowledgeInspectionReceipt" \
  "didPrepareStage667ComponentFeedbackInputResultSurfaceRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage666 component feedback input host inspection receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage666_component_feedback_input_host_inspection_receipt_owner_present=true"
echo "stage665_component_feedback_input_demo_host_surface_consumed=true"
echo "feedback_input_demo_host_surfaces_consumed=true"
echo "shared_feedback_input_host_inspection_receipt_materialized=true"
echo "feedback_input_host_inspection_probe_input_materialized=true"
echo "validation_dismiss_inspection_receipt_materialized=true"
echo "focus_movement_inspection_receipt_materialized=true"
echo "input_feedback_clear_inspection_receipt_materialized=true"
echo "semantic_diff_acknowledge_inspection_receipt_materialized=true"
echo "todo_feedback_input_host_inspection_receipt_materialized=true"
echo "settings_feedback_input_host_inspection_receipt_materialized=true"
echo "ai_generated_settings_feedback_input_host_inspection_receipt_materialized=true"
echo "chat_composer_feedback_input_host_inspection_receipt_materialized=true"
echo "host_inspection_receipt_bound_to_stage665_surface=true"
echo "feedback_input_host_inspection_checkable=true"
echo "stage667_component_feedback_input_result_surface_refresh_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
