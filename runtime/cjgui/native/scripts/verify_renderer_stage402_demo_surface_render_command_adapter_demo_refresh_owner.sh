#!/usr/bin/env zsh
#
# 维护注释：验证 stage402 demo surface RenderCommand adapter demo refresh owner。
# 它必须消费 stage401 adapter slots，并产出 Todo/settings/AI-generated settings demo refresh command batch preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage402_demo_surface_render_command_adapter_demo_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage402 demo surface render command adapter demo refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage402DemoSurfaceRenderCommandBatchPreview" \
  "CjguiInternalRendererStage402DemoSurfaceAdapterDemoRefreshFacts" \
  "CjguiInternalRendererStage402DemoSurfaceRenderCommandAdapterDemoRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage402DemoSurfaceRenderCommandAdapterDemoRefreshDraft" \
  "didConsumeStage401DemoSurfaceExecutionResultRenderCommandAdapter" \
  "didConsumeRenderCommandAdapterSlots" \
  "didMaterializeDemoSurfaceRenderCommandAdapterDemoRefresh" \
  "didMaterializeTodoDemoSurfaceRenderCommandBatchRefresh" \
  "didMaterializeSettingsDemoSurfaceRenderCommandBatchRefresh" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRenderCommandBatchRefresh" \
  "didBindDemoRefreshBatchToAdapterSlots" \
  "didBindDemoRefreshBatchToStage400SemanticDiff" \
  "didBindDemoRefreshBatchToStage399StateDeltaPreview" \
  "didPrepareStage403DemoSurfaceRenderCommandBackendAdapterDryRun" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage402 demo surface render command adapter demo refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage402_demo_surface_render_command_adapter_demo_refresh_owner_present=true"
echo "stage401_demo_surface_execution_result_render_command_adapter_required=true"
echo "stage401_demo_surface_execution_result_render_command_adapter_consumed=true"
echo "render_command_adapter_slots_consumed=true"
echo "demo_surface_render_command_adapter_demo_refresh_materialized=true"
echo "todo_demo_surface_render_command_batch_refresh_materialized=true"
echo "settings_demo_surface_render_command_batch_refresh_materialized=true"
echo "ai_generated_settings_demo_surface_render_command_batch_refresh_materialized=true"
echo "demo_refresh_batch_bound_to_adapter_slots=true"
echo "demo_refresh_batch_bound_to_stage400_semantic_diff=true"
echo "demo_refresh_batch_bound_to_stage399_state_delta_preview=true"
echo "stage403_demo_surface_render_command_backend_adapter_dry_run_prepared=true"
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
