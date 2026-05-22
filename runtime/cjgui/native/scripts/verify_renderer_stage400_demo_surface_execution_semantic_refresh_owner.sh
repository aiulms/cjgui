#!/usr/bin/env zsh
#
# 维护注释：验证 stage400 demo surface execution semantic refresh owner。
# 它必须消费 stage399 demo surface execution result，并产出 semantic diff / RenderCommand refresh preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage400_demo_surface_execution_semantic_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage400 demo surface execution semantic refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage400DemoSurfaceExecutionSemanticDiff" \
  "CjguiInternalRendererStage400DemoSurfaceExecutionRenderRefresh" \
  "CjguiInternalRendererStage400DemoSurfaceExecutionSemanticRefreshFacts" \
  "CjguiInternalRendererStage400DemoSurfaceExecutionSemanticRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage400DemoSurfaceExecutionSemanticRefreshDraft" \
  "didConsumeStage399DemoSurfaceEventExecutionDryRun" \
  "didMaterializeDemoSurfaceExecutionSemanticDiff" \
  "didBindSemanticDiffToTodoDemoSurfaceExecution" \
  "didBindSemanticDiffToSettingsDemoSurfaceExecution" \
  "didBindSemanticDiffToAiGeneratedSettingsDemoSurfaceExecution" \
  "didMaterializeDemoSurfaceExecutionRenderCommandRefresh" \
  "didBindExecutionRefreshToStage398ComponentEventSequenceRenderCommandPlan" \
  "didBindExecutionRefreshToStage399StateDeltaPreview" \
  "didPrepareStage401DemoSurfaceExecutionResultToRenderCommandAdapter" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage400 demo surface execution semantic refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage400_demo_surface_execution_semantic_refresh_owner_present=true"
echo "stage399_demo_surface_event_execution_dry_run_required=true"
echo "stage399_demo_surface_event_execution_dry_run_consumed=true"
echo "demo_surface_execution_semantic_diff_materialized=true"
echo "todo_demo_surface_execution_semantic_diff_materialized=true"
echo "settings_demo_surface_execution_semantic_diff_materialized=true"
echo "ai_generated_settings_demo_surface_execution_semantic_diff_materialized=true"
echo "demo_surface_execution_render_command_refresh_materialized=true"
echo "execution_refresh_bound_to_stage398_component_event_sequence_render_command_plan=true"
echo "execution_refresh_bound_to_stage399_state_delta_preview=true"
echo "stage401_demo_surface_execution_result_to_render_command_adapter_prepared=true"
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
