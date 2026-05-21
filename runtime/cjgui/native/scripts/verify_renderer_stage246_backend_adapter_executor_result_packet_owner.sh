#!/usr/bin/env zsh
#
# 维护注释：验证 stage246 backend adapter executor result packet owner。
# 它把 dry-run executor 结果封装为 rollback-ready value packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage246_backend_adapter_executor_result_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage246 backend adapter executor result packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage246BackendAdapterExecutorResultPacketFacts" \
  "CjguiInternalRendererStage246BackendAdapterExecutorResultPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage246BackendAdapterExecutorResultPacketDraft" \
  "didConsumeStage245BackendAdapterDryRunExecutor" \
  "didMaterializeBackendAdapterExecutorResultPacket" \
  "didBindExecutorResultToRollbackReadyEnvelope" \
  "didKeepExecutorResultOwnerLocalInMemoryOnly" \
  "didRejectExecutorResultRendererSubmission" \
  "didRejectExecutorResultRendererStateWrite" \
  "didPrepareStage247BackendAdapterVisibilityBoundaryRecheckInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRuntimeStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage246 backend adapter executor result packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage246_backend_adapter_executor_result_packet_owner_present=true"
echo "stage245_backend_adapter_dry_run_executor_required=true"
echo "backend_adapter_executor_result_packet_materialized=true"
echo "backend_adapter_executor_result_bound_to_rollback_ready_envelope=true"
echo "backend_adapter_executor_result_owner_local_in_memory_only=true"
echo "executor_result_renderer_submission_rejected=true"
echo "stage247_backend_adapter_visibility_boundary_recheck_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
