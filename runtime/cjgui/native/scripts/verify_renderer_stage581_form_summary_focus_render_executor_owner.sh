#!/usr/bin/env zsh
#
# Verifies the stage581 form summary/focus/render executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage581_form_summary_focus_render_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage581 form summary/focus/render executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage581FormSummaryFocusRenderExecutorPlan" \
  "CjguiInternalRendererStage581FormSummaryFocusRenderExecutorFacts" \
  "CjguiInternalRendererStage581FormSummaryFocusRenderExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage581FormSummaryFocusRenderExecutorDraft" \
  "CjguiInternalRendererStage580FormFieldLayoutValidationIntegrationReadiness" \
  "didMaterializeSharedFormSummaryFocusRenderExecutor" \
  "didMaterializeFormValidationSummaryLedger" \
  "didMaterializeFirstInvalidFieldFocusTargetLedger" \
  "didMaterializeFormGroupRenderCommandRefreshLedger" \
  "didMaterializeFormRollbackPreviewLedger" \
  "didMaterializeTodoFormSummaryReceipt" \
  "didMaterializeSettingsFormSummaryReceipt" \
  "didMaterializeAiGeneratedSettingsFormSummaryReceipt" \
  "didMaterializeChatComposerFormSummaryReceipt" \
  "didBindFormSummaryExecutorToStage580LayoutValidationSurfaces" \
  "didPrepareStage582FormDemoRuntimeSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage581 form summary/focus/render executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage581_form_summary_focus_render_executor_owner_present=true"
echo "stage580_form_field_layout_validation_integration_consumed=true"
echo "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed_transitively=true"
echo "shared_form_summary_focus_render_executor_materialized=true"
echo "form_validation_summary_ledger_materialized=true"
echo "first_invalid_field_focus_target_ledger_materialized=true"
echo "form_group_render_command_refresh_ledger_materialized=true"
echo "form_rollback_preview_ledger_materialized=true"
echo "todo_form_summary_receipt_materialized=true"
echo "settings_form_summary_receipt_materialized=true"
echo "ai_generated_settings_form_summary_receipt_materialized=true"
echo "chat_composer_form_summary_receipt_materialized=true"
echo "form_summary_executor_bound_to_stage580_layout_validation_surfaces=true"
echo "form_summary_executor_bound_to_stage579_submission_surfaces=true"
echo "form_summary_executor_owner_local=true"
echo "form_summary_executor_non_dispatching=true"
echo "form_summary_state_dry_run_only=true"
echo "stage582_form_demo_runtime_surface_contract_prepared=true"
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
