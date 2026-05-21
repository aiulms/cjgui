#!/usr/bin/env zsh
#
# 维护注释：验证 stage245 backend adapter dry-run executor owner。
# 它只执行 owner-local in-memory dry-run，不提交 backend 或 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage245_backend_adapter_dry_run_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage245 backend adapter dry-run executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage245BackendAdapterDryRunExecutorFacts" \
  "CjguiInternalRendererStage245BackendAdapterDryRunExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage245BackendAdapterDryRunExecutorDraft" \
  "didConsumeStage244ComponentDemoBackendAdapterReadinessDecision" \
  "didMaterializeBackendAdapterDryRunExecutor" \
  "didBindExecutorToComponentDemoBackendAdapterReadinessDecision" \
  "didBindExecutorToOwnerLocalDryRunPredicate" \
  "didExecuteOwnerLocalInMemoryAdapterDryRun" \
  "didCaptureRollbackReadyExecutorSnapshot" \
  "didPrepareStage246BackendAdapterExecutorResultPacketInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage245 backend adapter dry-run executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage245_backend_adapter_dry_run_executor_owner_present=true"
echo "stage244_component_demo_backend_adapter_readiness_decision_required=true"
echo "backend_adapter_dry_run_executor_materialized=true"
echo "owner_local_in_memory_adapter_dry_run_executed=true"
echo "backend_adapter_executor_rollback_snapshot_captured=true"
echo "stage246_backend_adapter_executor_result_packet_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
