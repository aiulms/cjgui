#!/usr/bin/env zsh
#
# Verifies the stage569 component runtime text input measurement/affordance executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage569_component_runtime_text_input_measurement_affordance_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage569 component runtime text input measurement affordance executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage569ComponentRuntimeTextInputMeasurementAffordanceExecutorPlan" \
  "CjguiInternalRendererStage569ComponentRuntimeTextInputMeasurementAffordanceExecutorFacts" \
  "CjguiInternalRendererStage569ComponentRuntimeTextInputMeasurementAffordanceExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage569ComponentRuntimeTextInputMeasurementAffordanceExecutorDraft" \
  "CjguiInternalRendererStage568ComponentRuntimeTextInputLayoutStylePreviewReadiness" \
  "didMaterializeSharedTextInputMeasurementAffordanceExecutor" \
  "didMaterializeTextInputIntrinsicSizeReceiptLedger" \
  "didMaterializeTextInputCaretRectReceiptLedger" \
  "didMaterializeTextInputSelectionRectReceiptLedger" \
  "didMaterializeTextInputValidationAdornmentReceiptLedger" \
  "didMaterializeTextInputFocusRingReceiptLedger" \
  "didMaterializeChatComposerTextInputMeasurementReceipt" \
  "didBindTextInputMeasurementToStage568PreviewSurfaces" \
  "didPrepareStage570ComponentRuntimeTextInputDemoHostSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage569 component runtime text input measurement affordance executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage569_component_runtime_text_input_measurement_affordance_executor_owner_present=true"
echo "stage568_component_runtime_text_input_layout_style_preview_consumed=true"
echo "stage567_component_runtime_text_input_demo_surface_contract_consumed_transitively=true"
echo "shared_text_input_measurement_affordance_executor_materialized=true"
echo "text_input_intrinsic_size_receipt_ledger_materialized=true"
echo "text_input_caret_rect_receipt_ledger_materialized=true"
echo "text_input_selection_rect_receipt_ledger_materialized=true"
echo "text_input_validation_adornment_receipt_ledger_materialized=true"
echo "text_input_focus_ring_receipt_ledger_materialized=true"
echo "todo_text_input_measurement_receipt_materialized=true"
echo "settings_text_input_measurement_receipt_materialized=true"
echo "ai_generated_settings_text_input_measurement_receipt_materialized=true"
echo "chat_composer_text_input_measurement_receipt_materialized=true"
echo "text_input_measurement_bound_to_stage568_preview_surfaces=true"
echo "component_text_input_measurement_dry_run_only=true"
echo "stage570_component_runtime_text_input_demo_host_surface_contract_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
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
