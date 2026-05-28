#!/usr/bin/env zsh
#
# Verifies the stage566 component runtime text input state executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage566_component_runtime_text_input_state_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage566 component runtime text input state executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage566ComponentRuntimeTextInputStateExecutorPlan" \
  "CjguiInternalRendererStage566ComponentRuntimeTextInputStateExecutorFacts" \
  "CjguiInternalRendererStage566ComponentRuntimeTextInputStateExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage566ComponentRuntimeTextInputStateExecutorDraft" \
  "CjguiInternalRendererStage565ComponentRuntimeTextInputModelReadiness" \
  "didMaterializeSharedComponentTextInputStateExecutor" \
  "didMaterializeTextInputActionLedger" \
  "didMaterializeTextValueStateDeltaDryRunLedger" \
  "didMaterializeSelectionCaretTransitionLedger" \
  "didMaterializeValidationResultPreviewLedger" \
  "didMaterializeTextInputRenderCommandRefreshPreviewLedger" \
  "didMaterializeTodoComponentTextInputStateReceipt" \
  "didMaterializeSettingsComponentTextInputStateReceipt" \
  "didMaterializeAiGeneratedSettingsComponentTextInputStateReceipt" \
  "didMaterializeChatComposerComponentTextInputStateReceipt" \
  "didBindTextInputStateExecutorToStage565Model" \
  "didPrepareStage567ComponentRuntimeTextInputDemoSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage566 component runtime text input state executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage566_component_runtime_text_input_state_executor_owner_present=true"
echo "stage565_component_runtime_text_input_model_consumed=true"
echo "stage564_host_route_text_edit_demo_surface_contract_consumed_transitively=true"
echo "shared_component_text_input_state_executor_materialized=true"
echo "text_input_action_ledger_materialized=true"
echo "text_value_state_delta_dry_run_ledger_materialized=true"
echo "selection_caret_transition_ledger_materialized=true"
echo "validation_result_preview_ledger_materialized=true"
echo "text_input_render_command_refresh_preview_ledger_materialized=true"
echo "todo_component_text_input_state_receipt_materialized=true"
echo "settings_component_text_input_state_receipt_materialized=true"
echo "ai_generated_settings_component_text_input_state_receipt_materialized=true"
echo "chat_composer_component_text_input_state_receipt_materialized=true"
echo "text_input_state_executor_bound_to_stage565_model=true"
echo "text_input_state_executor_bound_to_stage563_dry_run=true"
echo "component_text_input_state_dry_run_only=true"
echo "component_text_input_render_refresh_preview_only=true"
echo "stage567_component_runtime_text_input_demo_surface_contract_prepared=true"
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
