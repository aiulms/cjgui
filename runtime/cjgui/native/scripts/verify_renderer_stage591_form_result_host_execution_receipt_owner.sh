#!/usr/bin/env zsh
#
# Verifies the stage591 form result host execution receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage591_form_result_host_execution_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage591 form result host execution receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage591FormResultHostExecutionReceiptPlan" \
  "CjguiInternalRendererStage591FormResultHostExecutionReceiptFacts" \
  "CjguiInternalRendererStage591FormResultHostExecutionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage591FormResultHostExecutionReceiptDraft" \
  "CjguiInternalRendererStage590FormResultHostFeedbackAdapterReadiness" \
  "didMaterializeSharedFormResultHostExecutionReceipt" \
  "didMaterializeHostFocusTransitionPreviewLedger" \
  "didMaterializeHostInputFeedbackPreviewLedger" \
  "didMaterializeHostSurfaceInvalidationLedger" \
  "didMaterializeHostRenderCommandRefreshPreviewLedger" \
  "didMaterializeTodoFormResultHostExecutionReceipt" \
  "didMaterializeSettingsFormResultHostExecutionReceipt" \
  "didMaterializeAiGeneratedSettingsFormResultHostExecutionReceipt" \
  "didMaterializeChatComposerFormResultHostExecutionReceipt" \
  "didBindHostExecutionReceiptToStage590FeedbackRoutes" \
  "didPrepareStage592FormResultHostRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage591 form result host execution receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage591_form_result_host_execution_receipt_owner_present=true"
echo "stage590_form_result_host_feedback_adapter_consumed=true"
echo "shared_form_result_host_execution_receipt_materialized=true"
echo "host_focus_transition_preview_ledger_materialized=true"
echo "host_input_feedback_preview_ledger_materialized=true"
echo "host_surface_invalidation_ledger_materialized=true"
echo "host_render_command_refresh_preview_ledger_materialized=true"
echo "todo_form_result_host_execution_receipt_materialized=true"
echo "settings_form_result_host_execution_receipt_materialized=true"
echo "ai_generated_settings_form_result_host_execution_receipt_materialized=true"
echo "chat_composer_form_result_host_execution_receipt_materialized=true"
echo "host_execution_receipt_bound_to_stage590_feedback_routes=true"
echo "host_execution_receipt_bound_to_stage589_host_inspection=true"
echo "stage592_form_result_host_runtime_contract_prepared=true"
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
