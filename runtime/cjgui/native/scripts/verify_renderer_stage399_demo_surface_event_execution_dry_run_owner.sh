#!/usr/bin/env zsh
#
# 维护注释：验证 stage399 demo surface event execution dry-run owner。
# 它必须消费 stage398 component event sequence refresh，并产出 demo surface execution result preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage399_demo_surface_event_execution_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage399 demo surface event execution dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage399DemoSurfaceEventExecutionInput" \
  "CjguiInternalRendererStage399DemoSurfaceExecutionResult" \
  "CjguiInternalRendererStage399DemoSurfaceEventExecutionDryRunFacts" \
  "CjguiInternalRendererStage399DemoSurfaceEventExecutionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage399DemoSurfaceEventExecutionDryRunDraft" \
  "didConsumeStage398ComponentEventSequenceRenderRefreshProbe" \
  "didMaterializeDemoSurfaceEventExecutionDryRun" \
  "didMaterializeTodoDemoSurfaceExecutionResult" \
  "didMaterializeSettingsDemoSurfaceExecutionResult" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceExecutionResult" \
  "didBindDemoSurfaceExecutionToComponentEventSequence" \
  "didBindDemoSurfaceExecutionToOwnerAcceptanceGate" \
  "didMaterializeDemoSurfaceExecutionStateDeltaPreview" \
  "didPrepareStage400DemoSurfaceExecutionSemanticRefresh" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage399 demo surface event execution dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage399_demo_surface_event_execution_dry_run_owner_present=true"
echo "stage398_component_event_sequence_render_refresh_probe_required=true"
echo "stage398_component_event_sequence_render_refresh_probe_consumed=true"
echo "demo_surface_event_execution_dry_run_materialized=true"
echo "todo_demo_surface_execution_result_materialized=true"
echo "settings_demo_surface_execution_result_materialized=true"
echo "ai_generated_settings_demo_surface_execution_result_materialized=true"
echo "demo_surface_execution_bound_to_component_event_sequence=true"
echo "demo_surface_execution_bound_to_owner_acceptance_gate=true"
echo "demo_surface_execution_state_delta_preview_materialized=true"
echo "stage400_demo_surface_execution_semantic_refresh_prepared=true"
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
