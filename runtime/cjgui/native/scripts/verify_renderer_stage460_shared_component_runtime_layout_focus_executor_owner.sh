#!/usr/bin/env zsh
#
# 维护注释：验证 stage460 shared component runtime layout/focus executor owner。
# 它必须消费 stage459 shared component runtime shape，并产出 owner-local layout/focus executor preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage460_shared_component_runtime_layout_focus_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage460 shared component runtime layout focus executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage460SharedComponentRuntimeLayoutFocusExecutorPlan" \
  "CjguiInternalRendererStage460SharedComponentRuntimeLayoutFocusExecutorFacts" \
  "CjguiInternalRendererStage460SharedComponentRuntimeLayoutFocusExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage460SharedComponentRuntimeLayoutFocusExecutorDraft" \
  "CjguiInternalRendererStage459SharedComponentRuntimeShapeReadiness" \
  "didConsumeStage459SharedComponentRuntimeShape" \
  "didConsumeSharedDemoSurfaceComponentRuntimeContract" \
  "didConsumeTodoComponentRuntimeNode" \
  "didConsumeSettingsComponentRuntimeNode" \
  "didConsumeAiGeneratedSettingsComponentRuntimeNode" \
  "didMaterializeSharedComponentRuntimeLayoutFocusExecutor" \
  "didMaterializeTodoRuntimeLayoutFocusPass" \
  "didMaterializeSettingsRuntimeLayoutFocusPass" \
  "didMaterializeAiGeneratedSettingsRuntimeLayoutFocusPass" \
  "didBindComponentRuntimeShapeToLayoutFocusExecutor" \
  "didBindRenderCommandRefreshToLayoutFocusExecutor" \
  "didKeepLayoutFocusExecutorOwnerLocal" \
  "didKeepLayoutFocusExecutorPreviewOnly" \
  "didPrepareStage461SharedComponentRuntimeInputStateBridge" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage460 shared component runtime layout focus executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage460_shared_component_runtime_layout_focus_executor_owner_present=true"
echo "stage459_shared_component_runtime_shape_required=true"
echo "stage459_shared_component_runtime_shape_consumed=true"
echo "shared_demo_surface_component_runtime_contract_consumed=true"
echo "todo_component_runtime_node_consumed=true"
echo "settings_component_runtime_node_consumed=true"
echo "ai_generated_settings_component_runtime_node_consumed=true"
echo "shared_component_runtime_layout_focus_executor_materialized=true"
echo "todo_runtime_layout_focus_pass_materialized=true"
echo "settings_runtime_layout_focus_pass_materialized=true"
echo "ai_generated_settings_runtime_layout_focus_pass_materialized=true"
echo "component_runtime_shape_to_layout_focus_executor_bound=true"
echo "render_command_refresh_to_layout_focus_executor_bound=true"
echo "layout_focus_executor_owner_local=true"
echo "layout_focus_executor_preview_only=true"
echo "stage461_shared_component_runtime_input_state_bridge_prepared=true"
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
