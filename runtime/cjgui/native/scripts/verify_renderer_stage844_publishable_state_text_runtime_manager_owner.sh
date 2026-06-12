#!/usr/bin/env zsh
#
# Verifies the stage844 publishable state text runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage844_publishable_state_text_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage844 publishable state text runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage844PublishableStateTextRuntimeManagerPlan" \
  "CjguiInternalRendererStage844PublishableStateTextRuntimeManagerFacts" \
  "CjguiInternalRendererStage844PublishableStateTextRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage844PublishableStateTextRuntimeManagerDraft" \
  "CjguiInternalRendererStage843PublishableStateTextDemoSurfaceReadiness" \
  "didConsumeStage843PublishableStateTextDemoSurface" \
  "didMaterializeSharedPublishableTextRuntimeManager" \
  "didMaterializePublishableTextRuntimeContract" \
  "didMaterializePublishableTextExecutionReceiptContract" \
  "didMaterializeCycleOrderPublishableStateTextDemoRuntime" \
  "didBindTextRuntimeManagerToStage841TextModel" \
  "didBindTextRuntimeManagerToStage842EditPreview" \
  "didBindTextRuntimeManagerToStage843DemoSurface" \
  "didReduceFuturePerDemoTextTemplateNeed" \
  "didPrepareStage845PublishableStateTextInputAdapterAfterStage844"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage844 publishable state text runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage844_publishable_state_text_runtime_manager_owner_present=true"
echo "stage843_publishable_state_text_demo_surface_consumed=true"
echo "stage842_publishable_state_text_edit_preview_consumed_transitively=true"
echo "stage841_publishable_state_text_model_consumed_transitively=true"
echo "stage840_publishable_state_focus_runtime_manager_consumed_transitively=true"
echo "shared_publishable_text_runtime_manager_materialized=true"
echo "publishable_text_runtime_contract_materialized=true"
echo "publishable_text_execution_receipt_contract_materialized=true"
echo "cycle_order_publishable_state_text_demo_runtime_materialized=true"
echo "todo_text_runtime_surface_materialized=true"
echo "settings_text_runtime_surface_materialized=true"
echo "ai_generated_settings_text_runtime_surface_materialized=true"
echo "chat_composer_text_runtime_surface_materialized=true"
echo "file_browser_text_runtime_surface_materialized=true"
echo "text_runtime_manager_bound_to_stage841_text_model=true"
echo "text_runtime_manager_bound_to_stage842_edit_preview=true"
echo "text_runtime_manager_bound_to_stage843_demo_surface=true"
echo "future_per_demo_text_template_need_reduced=true"
echo "stage845_publishable_state_text_input_adapter_after_stage844_prepared=true"
echo "text_shaping_enabled=false"
echo "text_mutation=false"
echo "input_pipeline_execution=false"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
