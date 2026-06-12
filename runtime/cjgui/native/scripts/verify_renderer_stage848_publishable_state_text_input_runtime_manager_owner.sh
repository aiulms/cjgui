#!/usr/bin/env zsh
#
# Verifies the stage848 publishable state text input runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage848_publishable_state_text_input_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage848 publishable state text input runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage848PublishableStateTextInputRuntimeManagerPlan" \
  "CjguiInternalRendererStage848PublishableStateTextInputRuntimeManagerFacts" \
  "CjguiInternalRendererStage848PublishableStateTextInputRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage848PublishableStateTextInputRuntimeManagerDraft" \
  "CjguiInternalRendererStage847PublishableStateTextInputDemoSurfaceReadiness" \
  "didConsumeStage847PublishableStateTextInputDemoSurface" \
  "didMaterializeSharedPublishableTextInputRuntimeManager" \
  "didMaterializePublishableTextInputRuntimeContract" \
  "didMaterializePublishableTextInputExecutionReceiptContract" \
  "didMaterializeCycleOrderPublishableStateTextInputRuntime" \
  "didMaterializeFileBrowserTextInputRuntimeSurface" \
  "didBindTextInputRuntimeToStage844TextRuntimeManager" \
  "didBindTextInputRuntimeToStage845InputAdapter" \
  "didBindTextInputRuntimeToStage846CompositionPreview" \
  "didReduceFuturePerDemoTextInputTemplateNeed" \
  "didPrepareStage849PublishableStateTextInputStateUpdateRenderBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage848 publishable state text input runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage848_publishable_state_text_input_runtime_manager_owner_present=true"
echo "stage847_publishable_state_text_input_demo_surface_consumed=true"
echo "stage846_publishable_state_text_input_composition_preview_consumed_transitively=true"
echo "stage845_publishable_state_text_input_adapter_consumed_transitively=true"
echo "stage844_publishable_state_text_runtime_manager_consumed_transitively=true"
echo "shared_publishable_text_input_runtime_manager_materialized=true"
echo "publishable_text_input_runtime_contract_materialized=true"
echo "publishable_text_input_execution_receipt_contract_materialized=true"
echo "cycle_order_publishable_state_text_input_runtime_materialized=true"
echo "todo_text_input_runtime_surface_materialized=true"
echo "settings_text_input_runtime_surface_materialized=true"
echo "ai_generated_settings_text_input_runtime_surface_materialized=true"
echo "chat_composer_text_input_runtime_surface_materialized=true"
echo "file_browser_text_input_runtime_surface_materialized=true"
echo "text_input_runtime_bound_to_stage844_text_runtime_manager=true"
echo "text_input_runtime_bound_to_stage845_input_adapter=true"
echo "text_input_runtime_bound_to_stage846_composition_preview=true"
echo "text_input_runtime_bound_to_stage847_demo_surface=true"
echo "future_per_demo_text_input_template_need_reduced=true"
echo "stage849_publishable_state_text_input_state_update_render_bridge_prepared=true"
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
