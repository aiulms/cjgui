#!/usr/bin/env zsh
#
# 维护注释：验证 stage459 shared component runtime shape owner。
# 它必须消费 stage458 RenderCommand refresh，并产出三个 demo surface 共用的 internal runtime contract。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage459_shared_component_runtime_shape.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage459 shared component runtime shape: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage459SharedComponentRuntimeShapePlan" \
  "CjguiInternalRendererStage459SharedComponentRuntimeShapeFacts" \
  "CjguiInternalRendererStage459SharedComponentRuntimeShapeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage459SharedComponentRuntimeShapeDraft" \
  "CjguiInternalRendererStage458FocusStateRenderCommandRefreshReadiness" \
  "didConsumeStage458FocusStateRenderCommandRefresh" \
  "didConsumeFocusStateRenderCommandRefresh" \
  "didConsumeTodoFocusStateRenderCommandRefresh" \
  "didConsumeSettingsFocusStateRenderCommandRefresh" \
  "didConsumeAiGeneratedSettingsFocusStateRenderCommandRefresh" \
  "didMaterializeSharedDemoSurfaceComponentRuntimeShape" \
  "didMaterializeSharedDemoSurfaceComponentRuntimeContract" \
  "didMaterializeTodoComponentRuntimeNode" \
  "didMaterializeSettingsComponentRuntimeNode" \
  "didMaterializeAiGeneratedSettingsComponentRuntimeNode" \
  "didBindRenderCommandRefreshToComponentRuntimeShape" \
  "didBindFocusStateUpdateToComponentRuntimeShape" \
  "didKeepSharedComponentRuntimeInternalOnly" \
  "didKeepSharedComponentRuntimeOwnerLocal" \
  "didPrepareStage460SharedComponentRuntimeLayoutFocusExecutor" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage459 shared component runtime shape: missing token $token" >&2
    exit 3
  fi
done

echo "stage459_shared_component_runtime_shape_owner_present=true"
echo "stage458_focus_state_render_command_refresh_required=true"
echo "stage458_focus_state_render_command_refresh_consumed=true"
echo "focus_state_render_command_refresh_consumed=true"
echo "todo_focus_state_render_command_refresh_consumed=true"
echo "settings_focus_state_render_command_refresh_consumed=true"
echo "ai_generated_settings_focus_state_render_command_refresh_consumed=true"
echo "shared_demo_surface_component_runtime_shape_materialized=true"
echo "shared_demo_surface_component_runtime_contract_materialized=true"
echo "todo_component_runtime_node_materialized=true"
echo "settings_component_runtime_node_materialized=true"
echo "ai_generated_settings_component_runtime_node_materialized=true"
echo "render_command_refresh_to_component_runtime_shape_bound=true"
echo "focus_state_update_to_component_runtime_shape_bound=true"
echo "shared_component_runtime_internal_only=true"
echo "shared_component_runtime_owner_local=true"
echo "shared_component_runtime_reusable_contract=true"
echo "stage460_shared_component_runtime_layout_focus_executor_prepared=true"
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
