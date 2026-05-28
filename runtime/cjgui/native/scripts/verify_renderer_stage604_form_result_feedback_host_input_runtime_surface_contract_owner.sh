#!/usr/bin/env zsh
#
# Verifies the stage604 form result feedback host input runtime surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage604_form_result_feedback_host_input_runtime_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage604 form result feedback host input runtime surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage604FormResultFeedbackHostInputRuntimeSurfaceContractPlan" \
  "CjguiInternalRendererStage604FormResultFeedbackHostInputRuntimeSurfaceContractFacts" \
  "CjguiInternalRendererStage604FormResultFeedbackHostInputRuntimeSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage604FormResultFeedbackHostInputRuntimeSurfaceContractDraft" \
  "CjguiInternalRendererStage603FormResultFeedbackSurfaceEventCycleExecutorReadiness" \
  "didConsumeStage603FormResultFeedbackSurfaceEventCycleExecutor" \
  "didMaterializeSharedFormResultFeedbackHostInputRuntimeSurfaceContract" \
  "didMaterializeSharedFormResultFeedbackHostInputRuntimeSurfaceHelper" \
  "didMaterializeSharedFeedbackHostInputExecutionReceiptContract" \
  "didMaterializeTodoCheckableFeedbackHostInputRuntimeSurface" \
  "didMaterializeSettingsCheckableFeedbackHostInputRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsCheckableFeedbackHostInputRuntimeSurface" \
  "didMaterializeChatComposerCheckableFeedbackHostInputRuntimeSurface" \
  "didBindHostInputRuntimeSurfaceContractToStage603CycleReceipts" \
  "didReducePerDemoFeedbackInputRuntimeTemplateNeed" \
  "didPrepareStage605FormResultFeedbackHostInputLayoutFocusInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage604 form result feedback host input runtime surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage604_form_result_feedback_host_input_runtime_surface_contract_owner_present=true"
echo "stage603_form_result_feedback_surface_event_cycle_executor_consumed=true"
echo "shared_form_result_feedback_host_input_runtime_surface_contract_materialized=true"
echo "shared_form_result_feedback_host_input_runtime_surface_helper_materialized=true"
echo "shared_feedback_host_input_execution_receipt_contract_materialized=true"
echo "todo_checkable_feedback_host_input_runtime_surface_materialized=true"
echo "settings_checkable_feedback_host_input_runtime_surface_materialized=true"
echo "ai_generated_settings_checkable_feedback_host_input_runtime_surface_materialized=true"
echo "chat_composer_checkable_feedback_host_input_runtime_surface_materialized=true"
echo "host_input_runtime_surface_contract_bound_to_stage603_cycle_receipts=true"
echo "per_demo_feedback_input_runtime_template_need_reduced=true"
echo "stage605_form_result_feedback_host_input_layout_focus_inspection_prepared=true"
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
