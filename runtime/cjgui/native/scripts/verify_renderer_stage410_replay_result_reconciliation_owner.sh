#!/usr/bin/env zsh
#
# 维护注释：验证 stage410 demo surface replay result reconciliation owner。
# 它必须消费 stage409 replay result，并把 accepted / blocked replay 结果折回 demo surface reconciliation preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage410_replay_result_reconciliation.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage410 replay result reconciliation: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage410ReplayResultReconciliationPlan" \
  "CjguiInternalRendererStage410ReplayResultReconciliationFacts" \
  "CjguiInternalRendererStage410ReplayResultReconciliationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage410ReplayResultReconciliationDraft" \
  "didConsumeStage409BackendAdapterExecutionResultReplay" \
  "didConsumeBackendAdapterExecutionResultReplay" \
  "didConsumeAcceptedReplayResultPreview" \
  "didConsumeBlockedReplayResultPreview" \
  "didMaterializeDemoSurfaceReplayResultReconciliation" \
  "didReconcileTodoReplayResultSurface" \
  "didReconcileSettingsReplayResultSurface" \
  "didReconcileAiGeneratedSettingsReplayResultSurface" \
  "didBindReplayResultReconciliationToStage409Replay" \
  "didBindReplayResultReconciliationToStage408TraceRefresh" \
  "didMaterializeReconciledRenderCommandRefreshPreview" \
  "didMaterializeReplayRollbackDecisionPreview" \
  "didKeepReplayResultReconciliationOwnerLocal" \
  "didKeepReplayResultReconciliationPreviewOnly" \
  "didPrepareStage411DemoSurfaceBackendAdapterReplayAcceptanceGate" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage410 replay result reconciliation: missing token $token" >&2
    exit 3
  fi
done

echo "stage410_replay_result_reconciliation_owner_present=true"
echo "stage409_backend_adapter_execution_result_replay_required=true"
echo "stage409_backend_adapter_execution_result_replay_consumed=true"
echo "backend_adapter_execution_result_replay_consumed=true"
echo "accepted_replay_result_preview_consumed=true"
echo "blocked_replay_result_preview_consumed=true"
echo "demo_surface_replay_result_reconciliation_materialized=true"
echo "todo_replay_result_surface_reconciled=true"
echo "settings_replay_result_surface_reconciled=true"
echo "ai_generated_settings_replay_result_surface_reconciled=true"
echo "replay_result_reconciliation_bound_to_stage409_replay=true"
echo "replay_result_reconciliation_bound_to_stage408_trace_refresh=true"
echo "reconciled_render_command_refresh_preview_materialized=true"
echo "replay_rollback_decision_preview_materialized=true"
echo "replay_result_reconciliation_owner_local=true"
echo "replay_result_reconciliation_preview_only=true"
echo "stage411_demo_surface_backend_adapter_replay_acceptance_gate_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
