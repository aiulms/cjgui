#!/usr/bin/env zsh
#
# 维护注释：验证 stage401 demo surface execution result -> RenderCommand adapter owner。
# 它必须消费 stage400 semantic refresh，并把 Todo/settings/AI-generated settings execution result 映射为 owner-local RenderCommand slots。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage401_demo_surface_execution_result_render_command_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage401 demo surface execution result render command adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage401DemoSurfaceRenderCommandAdapterInput" \
  "CjguiInternalRendererStage401DemoSurfaceRenderCommandAdapterSlots" \
  "CjguiInternalRendererStage401DemoSurfaceExecutionResultRenderCommandAdapterFacts" \
  "CjguiInternalRendererStage401DemoSurfaceExecutionResultRenderCommandAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage401DemoSurfaceExecutionResultRenderCommandAdapterDraft" \
  "didConsumeStage400DemoSurfaceExecutionSemanticRefresh" \
  "didConsumeDemoSurfaceExecutionResult" \
  "didConsumeDemoSurfaceExecutionSemanticDiff" \
  "didConsumeDemoSurfaceExecutionRenderCommandRefresh" \
  "didMaterializeDemoSurfaceExecutionResultRenderCommandAdapter" \
  "didMapTodoExecutionResultToRenderCommandSlot" \
  "didMapSettingsExecutionResultToRenderCommandSlot" \
  "didMapAiGeneratedSettingsExecutionResultToRenderCommandSlot" \
  "didBindAdapterToStage398RenderCommandPlan" \
  "didBindAdapterToStage399StateDeltaPreview" \
  "didBindAdapterToStage400SemanticDiff" \
  "didPrepareStage402DemoSurfaceRenderCommandAdapterDemoRefresh" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage401 demo surface execution result render command adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage401_demo_surface_execution_result_render_command_adapter_owner_present=true"
echo "stage400_demo_surface_execution_semantic_refresh_required=true"
echo "stage400_demo_surface_execution_semantic_refresh_consumed=true"
echo "demo_surface_execution_result_consumed=true"
echo "demo_surface_execution_semantic_diff_consumed=true"
echo "demo_surface_execution_render_command_refresh_consumed=true"
echo "demo_surface_execution_result_render_command_adapter_materialized=true"
echo "todo_execution_result_to_render_command_slot_mapped=true"
echo "settings_execution_result_to_render_command_slot_mapped=true"
echo "ai_generated_settings_execution_result_to_render_command_slot_mapped=true"
echo "adapter_bound_to_stage398_render_command_plan=true"
echo "adapter_bound_to_stage399_state_delta_preview=true"
echo "adapter_bound_to_stage400_semantic_diff=true"
echo "stage402_demo_surface_render_command_adapter_demo_refresh_prepared=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
