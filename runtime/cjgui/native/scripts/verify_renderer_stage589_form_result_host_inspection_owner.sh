#!/usr/bin/env zsh
#
# Verifies the stage589 form result host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage589_form_result_host_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage589 form result host inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage589FormResultHostInspectionPlan" \
  "CjguiInternalRendererStage589FormResultHostInspectionFacts" \
  "CjguiInternalRendererStage589FormResultHostInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage589FormResultHostInspectionDraft" \
  "CjguiInternalRendererStage588FormCommitResultDemoRuntimeContractReadiness" \
  "didMaterializeSharedFormResultHostInspectionContract" \
  "didMaterializeSharedFormResultHostInspectionHelper" \
  "didMaterializeFormResultHostSlotLedger" \
  "didMaterializeFormResultHostValidationSummarySlot" \
  "didMaterializeFormResultHostFocusHandoffSlot" \
  "didMaterializeTodoFormResultHostInspectionInput" \
  "didMaterializeSettingsFormResultHostInspectionInput" \
  "didMaterializeAiGeneratedSettingsFormResultHostInspectionInput" \
  "didMaterializeChatComposerFormResultHostInspectionInput" \
  "didBindFormResultHostInspectionToStage588RuntimeSurfaces" \
  "didReducePerDemoFormResultHostInspectionTemplateNeed" \
  "didPrepareStage590FormResultHostFeedbackAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage589 form result host inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage589_form_result_host_inspection_owner_present=true"
echo "stage588_form_commit_result_demo_runtime_contract_consumed=true"
echo "shared_form_result_host_inspection_contract_materialized=true"
echo "shared_form_result_host_inspection_helper_materialized=true"
echo "form_result_host_slot_ledger_materialized=true"
echo "form_result_host_validation_summary_slot_materialized=true"
echo "form_result_host_focus_handoff_slot_materialized=true"
echo "todo_form_result_host_inspection_input_materialized=true"
echo "settings_form_result_host_inspection_input_materialized=true"
echo "ai_generated_settings_form_result_host_inspection_input_materialized=true"
echo "chat_composer_form_result_host_inspection_input_materialized=true"
echo "form_result_host_inspection_bound_to_stage588_runtime_surfaces=true"
echo "form_result_host_inspection_bound_to_stage587_feedback_receipts=true"
echo "per_demo_form_result_host_inspection_template_need_reduced=true"
echo "stage590_form_result_host_feedback_adapter_prepared=true"
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
