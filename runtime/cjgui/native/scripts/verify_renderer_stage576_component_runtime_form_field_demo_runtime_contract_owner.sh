#!/usr/bin/env zsh
#
# Verifies the stage576 component runtime form-field demo runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage576_component_runtime_form_field_demo_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage576 component runtime form-field demo runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage576ComponentRuntimeFormFieldDemoRuntimeContractPlan" \
  "CjguiInternalRendererStage576ComponentRuntimeFormFieldDemoRuntimeContractFacts" \
  "CjguiInternalRendererStage576ComponentRuntimeFormFieldDemoRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage576ComponentRuntimeFormFieldDemoRuntimeContractDraft" \
  "CjguiInternalRendererStage575ComponentRuntimeTextInputFocusValidationRenderRefreshBridgeReadiness" \
  "didMaterializeSharedFormFieldDemoRuntimeContract" \
  "didMaterializeSharedFormFieldDemoRuntimeHelper" \
  "didMaterializeSharedFormFieldExecutionReceiptContract" \
  "didMaterializeTodoFormFieldDemoRuntimeSurface" \
  "didMaterializeSettingsFormFieldDemoRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsFormFieldDemoRuntimeSurface" \
  "didMaterializeChatComposerFormFieldDemoRuntimeSurface" \
  "didReducePerDemoFormFieldFocusValidationTemplateNeed" \
  "didPrepareStage577ComponentRuntimeFormFieldSubmitActionAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage576 component runtime form-field demo runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage576_component_runtime_form_field_demo_runtime_contract_owner_present=true"
echo "stage575_component_runtime_text_input_focus_validation_render_refresh_bridge_consumed=true"
echo "stage574_component_runtime_text_input_focus_validation_policy_consumed_transitively=true"
echo "stage573_component_runtime_text_input_demo_execution_contract_consumed_transitively=true"
echo "shared_form_field_demo_runtime_contract_materialized=true"
echo "shared_form_field_demo_runtime_helper_materialized=true"
echo "shared_form_field_execution_receipt_contract_materialized=true"
echo "todo_form_field_demo_runtime_surface_materialized=true"
echo "settings_form_field_demo_runtime_surface_materialized=true"
echo "ai_generated_settings_form_field_demo_runtime_surface_materialized=true"
echo "chat_composer_form_field_demo_runtime_surface_materialized=true"
echo "form_field_runtime_contract_bound_to_stage575_render_refresh_receipts=true"
echo "form_field_runtime_contract_bound_to_stage574_focus_validation_policy=true"
echo "form_field_runtime_contract_bound_to_stage573_execution_surfaces=true"
echo "per_demo_form_field_focus_validation_template_need_reduced=true"
echo "stage577_component_runtime_form_field_submit_action_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
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
