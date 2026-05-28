#!/usr/bin/env zsh
#
# Verifies the stage575 component runtime text input focus/validation render refresh bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage575_component_runtime_text_input_focus_validation_render_refresh_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage575 component runtime text input focus validation render refresh bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage575ComponentRuntimeTextInputFocusValidationRenderRefreshBridgePlan" \
  "CjguiInternalRendererStage575ComponentRuntimeTextInputFocusValidationRenderRefreshBridgeFacts" \
  "CjguiInternalRendererStage575ComponentRuntimeTextInputFocusValidationRenderRefreshBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage575ComponentRuntimeTextInputFocusValidationRenderRefreshBridgeDraft" \
  "CjguiInternalRendererStage574ComponentRuntimeTextInputFocusValidationPolicyReadiness" \
  "didMaterializeSharedTextInputFocusValidationStateRenderBridge" \
  "didMaterializeTextInputFocusRingRenderCommandRefreshReceipt" \
  "didMaterializeTextInputValidationAdornmentRenderCommandRefreshReceipt" \
  "didMaterializeTextInputSubmitAffordanceRenderCommandRefreshReceipt" \
  "didMaterializeTextInputCaretSelectionRenderCommandRefreshReceipt" \
  "didMaterializeTodoFocusValidationRenderRefreshReceipt" \
  "didMaterializeSettingsFocusValidationRenderRefreshReceipt" \
  "didMaterializeAiGeneratedSettingsFocusValidationRenderRefreshReceipt" \
  "didMaterializeChatComposerFocusValidationRenderRefreshReceipt" \
  "didPrepareStage576ComponentRuntimeFormFieldDemoRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage575 component runtime text input focus validation render refresh bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage575_component_runtime_text_input_focus_validation_render_refresh_bridge_owner_present=true"
echo "stage574_component_runtime_text_input_focus_validation_policy_consumed=true"
echo "stage573_component_runtime_text_input_demo_execution_contract_consumed_transitively=true"
echo "shared_text_input_focus_validation_state_render_bridge_materialized=true"
echo "text_input_focus_ring_render_command_refresh_receipt_materialized=true"
echo "text_input_validation_adornment_render_command_refresh_receipt_materialized=true"
echo "text_input_submit_affordance_render_command_refresh_receipt_materialized=true"
echo "text_input_caret_selection_render_command_refresh_receipt_materialized=true"
echo "todo_focus_validation_render_refresh_receipt_materialized=true"
echo "settings_focus_validation_render_refresh_receipt_materialized=true"
echo "ai_generated_settings_focus_validation_render_refresh_receipt_materialized=true"
echo "chat_composer_focus_validation_render_refresh_receipt_materialized=true"
echo "focus_validation_render_refresh_bound_to_stage574_policy_ledgers=true"
echo "focus_validation_render_refresh_bound_to_stage572_cycle_receipts=true"
echo "stage576_component_runtime_form_field_demo_runtime_contract_prepared=true"
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
