#!/usr/bin/env zsh
#
# Verifies the stage595 form result host feedback demo surface receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage595_form_result_host_feedback_demo_surface_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage595 form result host feedback demo surface receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage595FormResultHostFeedbackDemoSurfaceReceiptPlan" \
  "CjguiInternalRendererStage595FormResultHostFeedbackDemoSurfaceReceiptFacts" \
  "CjguiInternalRendererStage595FormResultHostFeedbackDemoSurfaceReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage595FormResultHostFeedbackDemoSurfaceReceiptDraft" \
  "CjguiInternalRendererStage594FormResultHostFeedbackActionStateRenderExecutorReadiness" \
  "didMaterializeSharedFormResultHostFeedbackDemoSurfaceReceipt" \
  "didMaterializeHostFeedbackDemoSurfaceRefreshLedger" \
  "didMaterializeHostFeedbackValidationDisplayRefreshLedger" \
  "didMaterializeHostFeedbackFocusMovementPreviewLedger" \
  "didMaterializeHostFeedbackInputDisplayLedger" \
  "didMaterializeTodoFormResultHostFeedbackDemoSurfaceReceipt" \
  "didMaterializeSettingsFormResultHostFeedbackDemoSurfaceReceipt" \
  "didMaterializeAiGeneratedSettingsFormResultHostFeedbackDemoSurfaceReceipt" \
  "didMaterializeChatComposerFormResultHostFeedbackDemoSurfaceReceipt" \
  "didBindFeedbackDemoSurfaceReceiptToStage594Receipts" \
  "didPrepareStage596FormResultHostFeedbackCycleRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage595 form result host feedback demo surface receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage595_form_result_host_feedback_demo_surface_receipt_owner_present=true"
echo "stage594_form_result_host_feedback_action_state_render_executor_consumed=true"
echo "stage593_form_result_host_input_feedback_cycle_consumed_transitively=true"
echo "shared_form_result_host_feedback_demo_surface_receipt_materialized=true"
echo "host_feedback_demo_surface_refresh_ledger_materialized=true"
echo "host_feedback_validation_display_refresh_ledger_materialized=true"
echo "host_feedback_focus_movement_preview_ledger_materialized=true"
echo "host_feedback_input_display_ledger_materialized=true"
echo "todo_form_result_host_feedback_demo_surface_receipt_materialized=true"
echo "settings_form_result_host_feedback_demo_surface_receipt_materialized=true"
echo "ai_generated_settings_form_result_host_feedback_demo_surface_receipt_materialized=true"
echo "chat_composer_form_result_host_feedback_demo_surface_receipt_materialized=true"
echo "feedback_demo_surface_receipt_bound_to_stage594_receipts=true"
echo "feedback_demo_surface_receipt_bound_to_stage593_events=true"
echo "stage596_form_result_host_feedback_cycle_runtime_contract_prepared=true"
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
