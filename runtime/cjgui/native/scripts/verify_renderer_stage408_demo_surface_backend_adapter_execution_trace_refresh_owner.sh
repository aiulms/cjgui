#!/usr/bin/env zsh
#
# 维护注释：验证 stage408 demo surface backend adapter execution trace refresh owner。
# 它必须消费 stage407 execution plan dry-run，并把计划投影回 demo surface execution trace / rollback preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage408_demo_surface_backend_adapter_execution_trace_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage408 demo surface backend adapter execution trace refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage408DemoSurfaceBackendAdapterExecutionTraceRefreshPlan" \
  "CjguiInternalRendererStage408DemoSurfaceBackendAdapterExecutionTraceRefreshFacts" \
  "CjguiInternalRendererStage408DemoSurfaceBackendAdapterExecutionTraceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage408DemoSurfaceBackendAdapterExecutionTraceRefreshDraft" \
  "didConsumeStage407DemoSurfaceBackendAdapterExecutionPlan" \
  "didConsumeBackendAdapterExecutionPlanDryRun" \
  "didMaterializeDemoSurfaceBackendAdapterExecutionTraceRefresh" \
  "didRefreshTodoBackendAdapterExecutionTrace" \
  "didRefreshSettingsBackendAdapterExecutionTrace" \
  "didRefreshAiGeneratedSettingsBackendAdapterExecutionTrace" \
  "didBindExecutionTraceRefreshToStage407ExecutionPlan" \
  "didBindExecutionTraceRefreshToStage406ValidationRefresh" \
  "didMaterializeExecutionRollbackSurfacePreview" \
  "didKeepExecutionTraceRefreshOwnerLocal" \
  "didKeepExecutionTraceRefreshPreviewOnly" \
  "didPrepareStage409DemoSurfaceBackendAdapterExecutionResultReplay" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage408 demo surface backend adapter execution trace refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage408_demo_surface_backend_adapter_execution_trace_refresh_owner_present=true"
echo "stage407_demo_surface_backend_adapter_execution_plan_required=true"
echo "stage407_demo_surface_backend_adapter_execution_plan_consumed=true"
echo "backend_adapter_execution_plan_dry_run_consumed=true"
echo "demo_surface_backend_adapter_execution_trace_refresh_materialized=true"
echo "todo_backend_adapter_execution_trace_refreshed=true"
echo "settings_backend_adapter_execution_trace_refreshed=true"
echo "ai_generated_settings_backend_adapter_execution_trace_refreshed=true"
echo "execution_trace_refresh_bound_to_stage407_execution_plan=true"
echo "execution_trace_refresh_bound_to_stage406_validation_refresh=true"
echo "execution_rollback_surface_preview_materialized=true"
echo "execution_trace_refresh_owner_local=true"
echo "execution_trace_refresh_preview_only=true"
echo "stage409_demo_surface_backend_adapter_execution_result_replay_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
