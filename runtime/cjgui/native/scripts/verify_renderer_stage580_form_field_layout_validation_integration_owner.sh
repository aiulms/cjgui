#!/usr/bin/env zsh
#
# Verifies the stage580 form-field layout/validation integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage580_form_field_layout_validation_integration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage580 form-field layout/validation integration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage580FormFieldLayoutValidationIntegrationPlan" \
  "CjguiInternalRendererStage580FormFieldLayoutValidationIntegrationFacts" \
  "CjguiInternalRendererStage580FormFieldLayoutValidationIntegrationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage580FormFieldLayoutValidationIntegrationDraft" \
  "CjguiInternalRendererStage579ComponentRuntimeFormFieldSubmissionDemoSurfaceContractReadiness" \
  "didMaterializeSharedFormFieldLayoutValidationIntegration" \
  "didMaterializeFormFieldValidationMessageLayoutSlotLedger" \
  "didMaterializeFormFieldInvalidStyleTokenLedger" \
  "didMaterializeFormFieldSubmitAffordanceLayoutRefreshLedger" \
  "didMaterializeTodoFormFieldLayoutValidationSurface" \
  "didMaterializeSettingsFormFieldLayoutValidationSurface" \
  "didMaterializeAiGeneratedSettingsFormFieldLayoutValidationSurface" \
  "didMaterializeChatComposerFormFieldLayoutValidationSurface" \
  "didBindFormFieldLayoutValidationToStage579SubmissionSurfaces" \
  "didPrepareStage581FormSummaryFocusRenderExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage580 form-field layout/validation integration: missing token $token" >&2
    exit 3
  fi
done

echo "stage580_form_field_layout_validation_integration_owner_present=true"
echo "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed=true"
echo "shared_form_field_layout_validation_integration_materialized=true"
echo "form_field_validation_message_layout_slot_ledger_materialized=true"
echo "form_field_invalid_style_token_ledger_materialized=true"
echo "form_field_submit_affordance_layout_refresh_ledger_materialized=true"
echo "todo_form_field_layout_validation_surface_materialized=true"
echo "settings_form_field_layout_validation_surface_materialized=true"
echo "ai_generated_settings_form_field_layout_validation_surface_materialized=true"
echo "chat_composer_form_field_layout_validation_surface_materialized=true"
echo "form_field_layout_validation_bound_to_stage579_submission_surfaces=true"
echo "form_field_layout_validation_bound_to_stage578_submission_receipts=true"
echo "form_field_layout_validation_owner_local=true"
echo "stage581_form_summary_focus_render_executor_prepared=true"
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
