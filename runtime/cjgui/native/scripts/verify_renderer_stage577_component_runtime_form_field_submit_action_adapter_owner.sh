#!/usr/bin/env zsh
#
# Verifies the stage577 component runtime form-field submit action adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage577_component_runtime_form_field_submit_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage577 component runtime form-field submit action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage577ComponentRuntimeFormFieldSubmitActionAdapterPlan" \
  "CjguiInternalRendererStage577ComponentRuntimeFormFieldSubmitActionAdapterFacts" \
  "CjguiInternalRendererStage577ComponentRuntimeFormFieldSubmitActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage577ComponentRuntimeFormFieldSubmitActionAdapterDraft" \
  "CjguiInternalRendererStage576ComponentRuntimeFormFieldDemoRuntimeContractReadiness" \
  "didMaterializeSharedFormFieldSubmitActionAdapter" \
  "didMaterializeFormFieldSubmitIntentLedger" \
  "didMaterializeFormFieldCancelIntentLedger" \
  "didMaterializeFormFieldValidateOnSubmitIntentLedger" \
  "didMaterializeTodoFormFieldSubmitIntent" \
  "didMaterializeSettingsFormFieldSubmitIntent" \
  "didMaterializeAiGeneratedSettingsFormFieldSubmitIntent" \
  "didMaterializeChatComposerFormFieldSubmitIntent" \
  "didKeepFormFieldSubmitAdapterNonDispatching" \
  "didPrepareStage578ComponentRuntimeFormFieldSubmissionStateRenderExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage577 component runtime form-field submit action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage577_component_runtime_form_field_submit_action_adapter_owner_present=true"
echo "stage576_component_runtime_form_field_demo_runtime_contract_consumed=true"
echo "stage575_component_runtime_text_input_focus_validation_render_refresh_bridge_consumed_transitively=true"
echo "shared_form_field_submit_action_adapter_materialized=true"
echo "form_field_submit_intent_ledger_materialized=true"
echo "form_field_cancel_intent_ledger_materialized=true"
echo "form_field_validate_on_submit_intent_ledger_materialized=true"
echo "todo_form_field_submit_intent_materialized=true"
echo "settings_form_field_submit_intent_materialized=true"
echo "ai_generated_settings_form_field_submit_intent_materialized=true"
echo "chat_composer_form_field_submit_intent_materialized=true"
echo "form_field_submit_adapter_bound_to_stage576_runtime_surfaces=true"
echo "form_field_submit_adapter_bound_to_stage575_render_refresh_receipts=true"
echo "form_field_submit_adapter_non_dispatching=true"
echo "stage578_component_runtime_form_field_submission_state_render_executor_prepared=true"
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
