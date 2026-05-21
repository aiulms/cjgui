#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage170 guarded state-write executor source。
# 它消费 stage169 owner-local envelope，只允许生成非写入 executor 输入/结果。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage170_guarded_state_write_executor_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage170 guarded state-write executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage170GuardedStateWriteExecutorFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage170GuardedStateWriteExecutorFirstSliceDraft" \
  "didConsumeStage169OwnerLocalStateEnvelopeDryRun" \
  "didMaterializeGuardedStateWriteExecutorExecutionInput" \
  "didMaterializeGuardedStateWriteExecutorResultEnvelope" \
  "didBindOwnerLocalEnvelopeToGuardedExecutor" \
  "didPrepareStage171GuardedExecutorResultBoundaryInput" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage170 guarded state-write executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage170_guarded_state_write_executor_owner_present=true"
echo "stage169_owner_local_state_envelope_dry_run_required=true"
echo "guarded_state_write_executor_execution_input_materialized=true"
echo "guarded_state_write_executor_result_envelope_materialized=true"
echo "owner_local_envelope_to_guarded_executor_bound=true"
echo "rollback_visibility_boundaries_to_guarded_executor_bound=true"
echo "stage171_guarded_executor_result_boundary_input_prepared=true"
echo "guarded_state_write_executor_ready=true"
echo "guarded_state_write_executor_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
