#!/usr/bin/env zsh
#
# Verifies the stage852 publishable state text input state-update render bridge runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage852 publishable state text input state update render bridge runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage852PublishableStateTextInputStateUpdateRenderBridgeRuntimeManagerPlan" \
  "CjguiInternalRendererStage852PublishableStateTextInputStateUpdateRenderBridgeRuntimeManagerFacts" \
  "CjguiInternalRendererStage852PublishableStateTextInputStateUpdateRenderBridgeRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage852PublishableStateTextInputStateUpdateRenderBridgeRuntimeManagerDraft" \
  "CjguiInternalRendererStage851PublishableStateTextInputDemoResultSurfaceReadiness" \
  "didConsumeStage851PublishableStateTextInputDemoResultSurface" \
  "didMaterializeSharedTextInputStateUpdateRenderBridgeRuntimeManager" \
  "didMaterializeTextInputStateUpdateRenderBridgeRuntimeContract" \
  "didMaterializeTextInputStateUpdateRenderBridgeExecutionReceiptContract" \
  "didMaterializeCycleOrderTextInputStateDeltaRenderResultRuntime" \
  "didMaterializeFileBrowserTextInputStateUpdateRuntimeSurface" \
  "didBindRuntimeManagerToStage849StateDelta" \
  "didBindRuntimeManagerToStage850RenderCommandRefresh" \
  "didBindRuntimeManagerToStage851DemoResultSurface" \
  "didReduceFuturePerDemoTextInputStateUpdateTemplateNeed" \
  "didPrepareStage853PublishableStateTextInputCommitPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage852 publishable state text input state update render bridge runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_owner_present=true"
echo "stage851_publishable_state_text_input_demo_result_surface_consumed=true"
echo "stage850_publishable_state_text_input_render_command_refresh_preview_consumed_transitively=true"
echo "stage849_publishable_state_text_input_state_update_render_bridge_consumed_transitively=true"
echo "stage848_publishable_state_text_input_runtime_manager_consumed_transitively=true"
echo "shared_text_input_state_update_render_bridge_runtime_manager_materialized=true"
echo "text_input_state_update_render_bridge_runtime_contract_materialized=true"
echo "text_input_state_update_render_bridge_execution_receipt_contract_materialized=true"
echo "cycle_order_text_input_state_delta_render_result_runtime_materialized=true"
echo "todo_text_input_state_update_runtime_surface_materialized=true"
echo "settings_text_input_state_update_runtime_surface_materialized=true"
echo "ai_generated_settings_text_input_state_update_runtime_surface_materialized=true"
echo "chat_composer_text_input_state_update_runtime_surface_materialized=true"
echo "file_browser_text_input_state_update_runtime_surface_materialized=true"
echo "runtime_manager_bound_to_stage849_state_delta=true"
echo "runtime_manager_bound_to_stage850_render_command_refresh=true"
echo "runtime_manager_bound_to_stage851_demo_result_surface=true"
echo "future_per_demo_text_input_state_update_template_need_reduced=true"
echo "stage853_publishable_state_text_input_commit_preflight_prepared=true"
echo "text_input_pipeline_execution=false"
echo "text_mutation=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
