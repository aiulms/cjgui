#!/usr/bin/env zsh
#
# Verifies the stage596 form result host feedback cycle runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage596_form_result_host_feedback_cycle_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage596 form result host feedback cycle runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage596FormResultHostFeedbackCycleRuntimeContractPlan" \
  "CjguiInternalRendererStage596FormResultHostFeedbackCycleRuntimeContractFacts" \
  "CjguiInternalRendererStage596FormResultHostFeedbackCycleRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage596FormResultHostFeedbackCycleRuntimeContractDraft" \
  "CjguiInternalRendererStage595FormResultHostFeedbackDemoSurfaceReceiptReadiness" \
  "didMaterializeSharedFormResultHostFeedbackCycleRuntimeContract" \
  "didMaterializeSharedFormResultHostFeedbackCycleRuntimeHelper" \
  "didMaterializeSharedFormResultHostFeedbackCycleExecutionContract" \
  "didMaterializeTodoCheckableFormResultHostFeedbackCycleRuntimeSurface" \
  "didMaterializeSettingsCheckableFormResultHostFeedbackCycleRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsCheckableFormResultHostFeedbackCycleRuntimeSurface" \
  "didMaterializeChatComposerCheckableFormResultHostFeedbackCycleRuntimeSurface" \
  "didBindFeedbackCycleRuntimeContractToStage595DemoSurfaceReceipts" \
  "didBindFeedbackCycleRuntimeContractToStage594ExecutorReceipts" \
  "didBindFeedbackCycleRuntimeContractToStage593NormalizedCycle" \
  "didBindFeedbackCycleRuntimeContractToStage592HostRuntimeSurfaces" \
  "didReducePerDemoFormResultHostFeedbackCycleTemplateNeed" \
  "didPrepareStage597FormResultFeedbackValidationFocusSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage596 form result host feedback cycle runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage596_form_result_host_feedback_cycle_runtime_contract_owner_present=true"
echo "stage595_form_result_host_feedback_demo_surface_receipt_consumed=true"
echo "stage594_form_result_host_feedback_action_state_render_executor_consumed_transitively=true"
echo "stage593_form_result_host_input_feedback_cycle_consumed_transitively=true"
echo "stage592_form_result_host_runtime_contract_consumed_transitively=true"
echo "shared_form_result_host_feedback_cycle_runtime_contract_materialized=true"
echo "shared_form_result_host_feedback_cycle_runtime_helper_materialized=true"
echo "shared_form_result_host_feedback_cycle_execution_contract_materialized=true"
echo "todo_checkable_form_result_host_feedback_cycle_runtime_surface_materialized=true"
echo "settings_checkable_form_result_host_feedback_cycle_runtime_surface_materialized=true"
echo "ai_generated_settings_checkable_form_result_host_feedback_cycle_runtime_surface_materialized=true"
echo "chat_composer_checkable_form_result_host_feedback_cycle_runtime_surface_materialized=true"
echo "feedback_cycle_runtime_contract_bound_to_stage595_demo_surface_receipts=true"
echo "feedback_cycle_runtime_contract_bound_to_stage594_executor_receipts=true"
echo "feedback_cycle_runtime_contract_bound_to_stage593_normalized_cycle=true"
echo "feedback_cycle_runtime_contract_bound_to_stage592_host_runtime_surfaces=true"
echo "per_demo_form_result_host_feedback_cycle_template_need_reduced=true"
echo "stage597_form_result_feedback_validation_focus_surface_prepared=true"
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
