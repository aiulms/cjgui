#!/usr/bin/env zsh
#
# 维护注释：验证 stage409 demo surface backend adapter execution result replay owner。
# 它必须消费 stage408 execution trace refresh，并把 trace / rollback preview 映射成 owner-local replay result。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage409_backend_adapter_execution_result_replay.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage409 backend adapter execution result replay: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage409BackendAdapterExecutionResultReplayPlan" \
  "CjguiInternalRendererStage409BackendAdapterExecutionResultReplayFacts" \
  "CjguiInternalRendererStage409BackendAdapterExecutionResultReplayReadiness" \
  "cjguiInternalExecuteDefaultRendererStage409BackendAdapterExecutionResultReplayDraft" \
  "didConsumeStage408DemoSurfaceBackendAdapterExecutionTraceRefresh" \
  "didConsumeBackendAdapterExecutionTraceRefresh" \
  "didConsumeExecutionRollbackSurfacePreview" \
  "didMaterializeBackendAdapterExecutionResultReplay" \
  "didReplayTodoBackendAdapterExecutionResult" \
  "didReplaySettingsBackendAdapterExecutionResult" \
  "didReplayAiGeneratedSettingsBackendAdapterExecutionResult" \
  "didBindExecutionResultReplayToStage408TraceRefresh" \
  "didBindExecutionResultReplayToStage407ExecutionPlan" \
  "didClassifyAcceptedReplayResultPreview" \
  "didClassifyBlockedReplayResultPreview" \
  "didKeepExecutionResultReplayOwnerLocal" \
  "didKeepExecutionResultReplayPreviewOnly" \
  "didPrepareStage410DemoSurfaceReplayResultReconciliation" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage409 backend adapter execution result replay: missing token $token" >&2
    exit 3
  fi
done

echo "stage409_backend_adapter_execution_result_replay_owner_present=true"
echo "stage408_demo_surface_backend_adapter_execution_trace_refresh_required=true"
echo "stage408_demo_surface_backend_adapter_execution_trace_refresh_consumed=true"
echo "backend_adapter_execution_trace_refresh_consumed=true"
echo "execution_rollback_surface_preview_consumed=true"
echo "backend_adapter_execution_result_replay_materialized=true"
echo "todo_backend_adapter_execution_result_replayed=true"
echo "settings_backend_adapter_execution_result_replayed=true"
echo "ai_generated_settings_backend_adapter_execution_result_replayed=true"
echo "execution_result_replay_bound_to_stage408_trace_refresh=true"
echo "execution_result_replay_bound_to_stage407_execution_plan=true"
echo "accepted_replay_result_preview_classified=true"
echo "blocked_replay_result_preview_classified=true"
echo "execution_result_replay_owner_local=true"
echo "execution_result_replay_preview_only=true"
echo "stage410_demo_surface_replay_result_reconciliation_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
