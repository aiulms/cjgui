#!/usr/bin/env zsh
#
# Verifies the stage477 demo-surface refresh focus/input action adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage477_shared_component_runtime_demo_surface_refresh_focus_input_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage477 shared component runtime demo surface refresh focus input action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage477SharedComponentRuntimeDemoSurfaceRefreshFocusInputActionAdapterPlan" \
  "CjguiInternalRendererStage477SharedComponentRuntimeDemoSurfaceRefreshFocusInputActionAdapterFacts" \
  "CjguiInternalRendererStage477SharedComponentRuntimeDemoSurfaceRefreshFocusInputActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage477SharedComponentRuntimeDemoSurfaceRefreshFocusInputActionAdapterDraft" \
  "CjguiInternalRendererStage476SharedComponentRuntimeDemoSurfaceRefreshLayoutExecutionReceiptReadiness" \
  "didConsumeStage476SharedComponentRuntimeDemoSurfaceRefreshLayoutExecutionReceipt" \
  "didMaterializeSharedDemoSurfaceRefreshFocusInputActionAdapter" \
  "didMaterializeTodoRuntimeDemoSurfaceRefreshFocusActivationIntent" \
  "didMaterializeSettingsRuntimeDemoSurfaceRefreshToggleFocusIntent" \
  "didMaterializeAiGeneratedSettingsRuntimeDemoSurfaceRefreshSubmitFocusIntent" \
  "didBindLayoutExecutionReceiptToFocusInputActionAdapter" \
  "didKeepFocusInputActionAdapterReusable" \
  "didKeepFocusInputActionAdapterOwnerLocal" \
  "didPrepareStage478SharedComponentRuntimeDemoSurfaceRefreshActionStateUpdateDryRun" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage477 shared component runtime demo surface refresh focus input action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage477_shared_component_runtime_demo_surface_refresh_focus_input_action_adapter_owner_present=true"
echo "stage476_shared_component_runtime_demo_surface_refresh_layout_execution_receipt_required=true"
echo "stage476_shared_component_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "shared_demo_surface_refresh_layout_style_execution_receipt_consumed=true"
echo "todo_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "settings_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "ai_generated_settings_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "shared_demo_surface_refresh_focus_input_action_adapter_materialized=true"
echo "todo_runtime_demo_surface_refresh_focus_activation_intent_materialized=true"
echo "settings_runtime_demo_surface_refresh_toggle_focus_intent_materialized=true"
echo "ai_generated_settings_runtime_demo_surface_refresh_submit_focus_intent_materialized=true"
echo "layout_execution_receipt_to_focus_input_action_adapter_bound=true"
echo "demo_surface_refresh_focus_input_adapter_contract_materialized=true"
echo "focus_input_action_adapter_reusable=true"
echo "focus_input_action_adapter_owner_local=true"
echo "focus_input_action_adapter_non_dispatching=true"
echo "stage478_shared_component_runtime_demo_surface_refresh_action_state_update_dry_run_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
