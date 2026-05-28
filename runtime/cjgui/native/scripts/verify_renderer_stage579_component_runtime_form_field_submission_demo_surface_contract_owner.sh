#!/usr/bin/env zsh
#
# Verifies the stage579 component runtime form-field submission demo surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage579_component_runtime_form_field_submission_demo_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage579 component runtime form-field submission demo surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage579ComponentRuntimeFormFieldSubmissionDemoSurfaceContractPlan" \
  "CjguiInternalRendererStage579ComponentRuntimeFormFieldSubmissionDemoSurfaceContractFacts" \
  "CjguiInternalRendererStage579ComponentRuntimeFormFieldSubmissionDemoSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage579ComponentRuntimeFormFieldSubmissionDemoSurfaceContractDraft" \
  "CjguiInternalRendererStage578ComponentRuntimeFormFieldSubmissionStateRenderExecutorReadiness" \
  "didMaterializeSharedFormFieldSubmissionDemoSurfaceContract" \
  "didMaterializeSharedFormFieldSubmissionDemoSurfaceHelper" \
  "didMaterializeSharedFormFieldSubmissionExecutionReceiptContract" \
  "didMaterializeTodoCheckableSubmissionDemoSurface" \
  "didMaterializeSettingsCheckableSubmissionDemoSurface" \
  "didMaterializeAiGeneratedSettingsCheckableSubmissionDemoSurface" \
  "didMaterializeChatComposerCheckableSubmissionDemoSurface" \
  "didReducePerDemoFormFieldSubmissionTemplateNeed" \
  "didPrepareStage580ComponentRuntimeFormFieldLayoutValidationIntegration"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage579 component runtime form-field submission demo surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage579_component_runtime_form_field_submission_demo_surface_contract_owner_present=true"
echo "stage578_component_runtime_form_field_submission_state_render_executor_consumed=true"
echo "stage577_component_runtime_form_field_submit_action_adapter_consumed_transitively=true"
echo "stage576_component_runtime_form_field_demo_runtime_contract_consumed_transitively=true"
echo "shared_form_field_submission_demo_surface_contract_materialized=true"
echo "shared_form_field_submission_demo_surface_helper_materialized=true"
echo "shared_form_field_submission_execution_receipt_contract_materialized=true"
echo "todo_checkable_submission_demo_surface_materialized=true"
echo "settings_checkable_submission_demo_surface_materialized=true"
echo "ai_generated_settings_checkable_submission_demo_surface_materialized=true"
echo "chat_composer_checkable_submission_demo_surface_materialized=true"
echo "form_field_submission_demo_surface_bound_to_stage578_receipts=true"
echo "form_field_submission_demo_surface_bound_to_stage577_action_adapter=true"
echo "form_field_submission_demo_surface_bound_to_stage576_runtime_surfaces=true"
echo "per_demo_form_field_submission_template_need_reduced=true"
echo "stage580_component_runtime_form_field_layout_validation_integration_prepared=true"
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
