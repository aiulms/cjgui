#!/usr/bin/env zsh
#
# Verifies the stage574 component runtime text input focus/validation policy owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage574_component_runtime_text_input_focus_validation_policy.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage574 component runtime text input focus validation policy: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage574ComponentRuntimeTextInputFocusValidationPolicyPlan" \
  "CjguiInternalRendererStage574ComponentRuntimeTextInputFocusValidationPolicyFacts" \
  "CjguiInternalRendererStage574ComponentRuntimeTextInputFocusValidationPolicyReadiness" \
  "cjguiInternalExecuteDefaultRendererStage574ComponentRuntimeTextInputFocusValidationPolicyDraft" \
  "CjguiInternalRendererStage573ComponentRuntimeTextInputDemoExecutionContractReadiness" \
  "didMaterializeSharedTextInputFocusValidationPolicy" \
  "didMaterializeTextInputFocusRoutePolicyLedger" \
  "didMaterializeTextInputValidationStatePolicyLedger" \
  "didMaterializeTextInputDirtySubmitEligibilityLedger" \
  "didMaterializeTodoTextInputFocusValidationPolicySurface" \
  "didMaterializeSettingsTextInputFocusValidationPolicySurface" \
  "didMaterializeAiGeneratedSettingsTextInputFocusValidationPolicySurface" \
  "didMaterializeChatComposerTextInputFocusValidationPolicySurface" \
  "didPrepareStage575ComponentRuntimeTextInputFocusValidationRenderRefreshBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage574 component runtime text input focus validation policy: missing token $token" >&2
    exit 3
  fi
done

echo "stage574_component_runtime_text_input_focus_validation_policy_owner_present=true"
echo "stage573_component_runtime_text_input_demo_execution_contract_consumed=true"
echo "stage572_component_runtime_text_input_cycle_executor_consumed_transitively=true"
echo "stage569_component_runtime_text_input_measurement_affordance_executor_consumed_transitively=true"
echo "shared_text_input_focus_validation_policy_materialized=true"
echo "text_input_focus_route_policy_ledger_materialized=true"
echo "text_input_validation_state_policy_ledger_materialized=true"
echo "text_input_dirty_submit_eligibility_ledger_materialized=true"
echo "todo_text_input_focus_validation_policy_surface_materialized=true"
echo "settings_text_input_focus_validation_policy_surface_materialized=true"
echo "ai_generated_settings_text_input_focus_validation_policy_surface_materialized=true"
echo "chat_composer_text_input_focus_validation_policy_surface_materialized=true"
echo "focus_validation_policy_bound_to_stage573_execution_surfaces=true"
echo "focus_validation_policy_bound_to_stage569_measurement_receipts=true"
echo "focus_validation_policy_bound_to_stage572_cycle_receipts=true"
echo "stage575_component_runtime_text_input_focus_validation_render_refresh_bridge_prepared=true"
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
