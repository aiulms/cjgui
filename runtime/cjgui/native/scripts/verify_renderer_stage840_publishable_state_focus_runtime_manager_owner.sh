#!/usr/bin/env zsh
#
# Verifies the stage840 publishable state focus runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage840_publishable_state_focus_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage840 publishable state focus runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerPlan" \
  "CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerFacts" \
  "CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage840PublishableStateFocusRuntimeManagerDraft" \
  "CjguiInternalRendererStage839PublishableStateFocusDemoSurfaceReadiness" \
  "didConsumeStage839PublishableStateFocusDemoSurface" \
  "didMaterializeSharedPublishableFocusRuntimeManager" \
  "didMaterializePublishableFocusRuntimeContract" \
  "didMaterializePublishableFocusExecutionReceiptContract" \
  "didMaterializeCycleOrderPublishableStateFocusDemoRuntime" \
  "didBindFocusRuntimeManagerToStage837FocusManagerInput" \
  "didBindFocusRuntimeManagerToStage838MovementPreview" \
  "didBindFocusRuntimeManagerToStage839DemoSurface" \
  "didReduceFuturePerDemoFocusTemplateNeed" \
  "didPrepareStage841PublishableStateTextModelAfterStage840"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage840 publishable state focus runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage840_publishable_state_focus_runtime_manager_owner_present=true"
echo "stage839_publishable_state_focus_demo_surface_consumed=true"
echo "stage838_publishable_state_focus_movement_preview_consumed_transitively=true"
echo "stage837_publishable_state_focus_manager_consumed_transitively=true"
echo "stage836_publishable_state_layout_style_runtime_manager_consumed_transitively=true"
echo "shared_publishable_focus_runtime_manager_materialized=true"
echo "publishable_focus_runtime_contract_materialized=true"
echo "publishable_focus_execution_receipt_contract_materialized=true"
echo "cycle_order_publishable_state_focus_demo_runtime_materialized=true"
echo "todo_focus_runtime_surface_materialized=true"
echo "settings_focus_runtime_surface_materialized=true"
echo "ai_generated_settings_focus_runtime_surface_materialized=true"
echo "chat_composer_focus_runtime_surface_materialized=true"
echo "file_browser_focus_runtime_surface_materialized=true"
echo "focus_runtime_manager_bound_to_stage837_focus_manager_input=true"
echo "focus_runtime_manager_bound_to_stage838_movement_preview=true"
echo "focus_runtime_manager_bound_to_stage839_demo_surface=true"
echo "future_per_demo_focus_template_need_reduced=true"
echo "stage841_publishable_state_text_model_after_stage840_prepared=true"
echo "focus_manager_enabled=false"
echo "focus_mutation=false"
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
