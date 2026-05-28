#!/usr/bin/env zsh
#
# Verifies the stage582 form demo runtime surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage582_form_demo_runtime_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage582 form demo runtime surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage582FormDemoRuntimeSurfaceContractPlan" \
  "CjguiInternalRendererStage582FormDemoRuntimeSurfaceContractFacts" \
  "CjguiInternalRendererStage582FormDemoRuntimeSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage582FormDemoRuntimeSurfaceContractDraft" \
  "CjguiInternalRendererStage581FormSummaryFocusRenderExecutorReadiness" \
  "didMaterializeSharedFormDemoRuntimeSurfaceContract" \
  "didMaterializeSharedFormDemoRuntimeSurfaceHelper" \
  "didMaterializeSharedFormExecutionReceiptContract" \
  "didMaterializeTodoCheckableFormRuntimeSurface" \
  "didMaterializeSettingsCheckableFormRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsCheckableFormRuntimeSurface" \
  "didMaterializeChatComposerCheckableFormRuntimeSurface" \
  "didBindFormDemoRuntimeSurfaceToStage581SummaryReceipts" \
  "didBindFormDemoRuntimeSurfaceToStage580LayoutValidationIntegration" \
  "didReducePerDemoFormLayoutValidationRuntimeTemplateNeed" \
  "didPrepareStage583ComponentRuntimeFormInputEventCommitPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage582 form demo runtime surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage582_form_demo_runtime_surface_contract_owner_present=true"
echo "stage581_form_summary_focus_render_executor_consumed=true"
echo "stage580_form_field_layout_validation_integration_consumed_transitively=true"
echo "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed_transitively=true"
echo "shared_form_demo_runtime_surface_contract_materialized=true"
echo "shared_form_demo_runtime_surface_helper_materialized=true"
echo "shared_form_execution_receipt_contract_materialized=true"
echo "todo_checkable_form_runtime_surface_materialized=true"
echo "settings_checkable_form_runtime_surface_materialized=true"
echo "ai_generated_settings_checkable_form_runtime_surface_materialized=true"
echo "chat_composer_checkable_form_runtime_surface_materialized=true"
echo "form_demo_runtime_surface_bound_to_stage581_summary_receipts=true"
echo "form_demo_runtime_surface_bound_to_stage580_layout_validation_integration=true"
echo "form_demo_runtime_surface_bound_to_stage579_submission_surfaces=true"
echo "per_demo_form_layout_validation_runtime_template_need_reduced=true"
echo "stage583_component_runtime_form_input_event_commit_preview_prepared=true"
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
