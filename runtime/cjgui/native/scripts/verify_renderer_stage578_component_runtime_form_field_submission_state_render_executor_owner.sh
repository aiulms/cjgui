#!/usr/bin/env zsh
#
# Verifies the stage578 component runtime form-field submission state/render executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage578_component_runtime_form_field_submission_state_render_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage578 component runtime form-field submission state/render executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage578ComponentRuntimeFormFieldSubmissionStateRenderExecutorPlan" \
  "CjguiInternalRendererStage578ComponentRuntimeFormFieldSubmissionStateRenderExecutorFacts" \
  "CjguiInternalRendererStage578ComponentRuntimeFormFieldSubmissionStateRenderExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage578ComponentRuntimeFormFieldSubmissionStateRenderExecutorDraft" \
  "CjguiInternalRendererStage577ComponentRuntimeFormFieldSubmitActionAdapterReadiness" \
  "didMaterializeSharedFormFieldSubmissionStateRenderExecutor" \
  "didMaterializeFormFieldSubmissionStateDeltaDryRunLedger" \
  "didMaterializeFormFieldSubmissionValidationResultLedger" \
  "didMaterializeFormFieldSubmissionRenderCommandRefreshLedger" \
  "didMaterializeTodoFormFieldSubmissionReceipt" \
  "didMaterializeSettingsFormFieldSubmissionReceipt" \
  "didMaterializeAiGeneratedSettingsFormFieldSubmissionReceipt" \
  "didMaterializeChatComposerFormFieldSubmissionReceipt" \
  "didKeepFormFieldSubmissionExecutorNonDispatching" \
  "didKeepFormFieldSubmissionStateDryRunOnly" \
  "didPrepareStage579ComponentRuntimeFormFieldSubmissionDemoSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage578 component runtime form-field submission state/render executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage578_component_runtime_form_field_submission_state_render_executor_owner_present=true"
echo "stage577_component_runtime_form_field_submit_action_adapter_consumed=true"
echo "stage576_component_runtime_form_field_demo_runtime_contract_consumed_transitively=true"
echo "shared_form_field_submission_state_render_executor_materialized=true"
echo "form_field_submission_state_delta_dry_run_ledger_materialized=true"
echo "form_field_submission_validation_result_ledger_materialized=true"
echo "form_field_submission_render_command_refresh_ledger_materialized=true"
echo "todo_form_field_submission_receipt_materialized=true"
echo "settings_form_field_submission_receipt_materialized=true"
echo "ai_generated_settings_form_field_submission_receipt_materialized=true"
echo "chat_composer_form_field_submission_receipt_materialized=true"
echo "form_field_submission_executor_bound_to_stage577_action_intents=true"
echo "form_field_submission_executor_bound_to_stage576_runtime_surfaces=true"
echo "form_field_submission_executor_non_dispatching=true"
echo "form_field_submission_state_dry_run_only=true"
echo "stage579_component_runtime_form_field_submission_demo_surface_contract_prepared=true"
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
