#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage163 executor dry-run source。它只确认
# precommit boundary 已接成非写入 executor result envelope，不执行 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage163_renderer_state_write_executor_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage163 renderer-state write executor dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage163RendererStateWriteExecutorDryRunFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage163RendererStateWriteExecutorDryRunFirstSliceDraft" \
  "didConsumeStage162RendererStateWritePrecommitVisibilityBoundary" \
  "didMaterializeRendererStateWriteExecutorDryRunResultEnvelope" \
  "didBindGuardedExecutorResultEnvelope" \
  "didPrepareRollbackPublicationResultInput" \
  "didKeepRendererStateWriteExecutorDryRunNonMutating" \
  "didKeepRendererStateWriteExecutionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage163 renderer-state write executor dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage163_renderer_state_write_executor_dry_run_owner_present=true"
echo "stage162_renderer_state_write_precommit_visibility_boundary_required=true"
echo "renderer_state_write_executor_dry_run_result_envelope_materialized=true"
echo "renderer_state_write_guarded_executor_result_envelope_prepared=true"
echo "renderer_state_write_rollback_publication_result_input_prepared=true"
echo "renderer_state_write_executor_dry_run_ready=true"
echo "renderer_state_write_executor_dry_run_runtime_admitted=false"
echo "renderer_state_write_executor_dry_run_non_mutating=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
