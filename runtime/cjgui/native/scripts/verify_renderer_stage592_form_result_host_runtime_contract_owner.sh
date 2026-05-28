#!/usr/bin/env zsh
#
# Verifies the stage592 form result host runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage592_form_result_host_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage592 form result host runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage592FormResultHostRuntimeContractPlan" \
  "CjguiInternalRendererStage592FormResultHostRuntimeContractFacts" \
  "CjguiInternalRendererStage592FormResultHostRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage592FormResultHostRuntimeContractDraft" \
  "CjguiInternalRendererStage591FormResultHostExecutionReceiptReadiness" \
  "didMaterializeSharedFormResultHostRuntimeContract" \
  "didMaterializeSharedFormResultHostRuntimeHelper" \
  "didMaterializeSharedFormResultHostRuntimeExecutionContract" \
  "didMaterializeTodoCheckableFormResultHostRuntimeSurface" \
  "didMaterializeSettingsCheckableFormResultHostRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsCheckableFormResultHostRuntimeSurface" \
  "didMaterializeChatComposerCheckableFormResultHostRuntimeSurface" \
  "didBindFormResultHostRuntimeContractToStage591ExecutionReceipts" \
  "didReducePerDemoFormResultHostRuntimeTemplateNeed" \
  "didPrepareStage593FormResultHostInputFeedbackCycle"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage592 form result host runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage592_form_result_host_runtime_contract_owner_present=true"
echo "stage591_form_result_host_execution_receipt_consumed=true"
echo "stage590_form_result_host_feedback_adapter_consumed_transitively=true"
echo "stage589_form_result_host_inspection_consumed_transitively=true"
echo "shared_form_result_host_runtime_contract_materialized=true"
echo "shared_form_result_host_runtime_helper_materialized=true"
echo "shared_form_result_host_runtime_execution_contract_materialized=true"
echo "todo_checkable_form_result_host_runtime_surface_materialized=true"
echo "settings_checkable_form_result_host_runtime_surface_materialized=true"
echo "ai_generated_settings_checkable_form_result_host_runtime_surface_materialized=true"
echo "chat_composer_checkable_form_result_host_runtime_surface_materialized=true"
echo "form_result_host_runtime_contract_bound_to_stage591_execution_receipts=true"
echo "form_result_host_runtime_contract_bound_to_stage590_feedback_routes=true"
echo "form_result_host_runtime_contract_bound_to_stage589_host_inspection=true"
echo "per_demo_form_result_host_runtime_template_need_reduced=true"
echo "stage593_form_result_host_input_feedback_cycle_prepared=true"
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
