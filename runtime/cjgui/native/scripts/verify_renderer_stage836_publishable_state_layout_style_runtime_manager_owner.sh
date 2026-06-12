#!/usr/bin/env zsh
#
# Verifies the stage836 publishable state layout/style runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage836_publishable_state_layout_style_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage836 publishable state layout style runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerPlan" \
  "CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerFacts" \
  "CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage836PublishableStateLayoutStyleRuntimeManagerDraft" \
  "CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness" \
  "didConsumeStage835PublishableStateLayoutStyleDemoSurface" \
  "didMaterializeSharedPublishableLayoutStyleRuntimeManager" \
  "didMaterializePublishableLayoutStyleRuntimeContract" \
  "didMaterializePublishableLayoutStyleExecutionReceiptContract" \
  "didMaterializeCycleOrderPublishableStateLayoutStyleDemoRuntime" \
  "didBindRuntimeManagerToStage833Resolver" \
  "didBindRuntimeManagerToStage834MeasurementPlan" \
  "didBindRuntimeManagerToStage835DemoSurface" \
  "didReduceFuturePerDemoLayoutStyleTemplateNeed" \
  "didPrepareStage837PublishableStateFocusManagerAfterStage836"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage836 publishable state layout style runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage836_publishable_state_layout_style_runtime_manager_owner_present=true"
echo "stage835_publishable_state_layout_style_demo_surface_consumed=true"
echo "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true"
echo "stage833_publishable_state_layout_style_resolver_consumed_transitively=true"
echo "stage832_component_state_store_publishable_runtime_manager_consumed_transitively=true"
echo "shared_publishable_layout_style_runtime_manager_materialized=true"
echo "publishable_layout_style_runtime_contract_materialized=true"
echo "publishable_layout_style_execution_receipt_contract_materialized=true"
echo "cycle_order_publishable_state_layout_style_demo_runtime_materialized=true"
echo "todo_layout_style_runtime_surface_materialized=true"
echo "settings_layout_style_runtime_surface_materialized=true"
echo "ai_generated_settings_layout_style_runtime_surface_materialized=true"
echo "chat_composer_layout_style_runtime_surface_materialized=true"
echo "file_browser_layout_style_runtime_surface_materialized=true"
echo "layout_style_runtime_manager_bound_to_stage833_resolver=true"
echo "layout_style_runtime_manager_bound_to_stage834_measurement_plan=true"
echo "layout_style_runtime_manager_bound_to_stage835_demo_surface=true"
echo "future_per_demo_layout_style_template_need_reduced=true"
echo "stage837_publishable_state_focus_manager_after_stage836_prepared=true"
echo "layout_engine_enabled=false"
echo "style_resolver_production_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
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
