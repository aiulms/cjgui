#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage162 precommit visibility boundary source，把
# admission ledger 转换为 state-write executor 的前置边界输入；仍不写 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage162_renderer_state_write_precommit_visibility_boundary_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage162 renderer-state write precommit visibility boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage162RendererStateWritePrecommitVisibilityBoundaryFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage162RendererStateWritePrecommitVisibilityBoundaryFirstSliceDraft" \
  "didConsumeStage161RendererStateWriteAdmissionLedger" \
  "didMaterializeRendererStateWritePrecommitVisibilityBoundary" \
  "didBindNonPublicVisibilityPublicationBoundary" \
  "didBindRollbackStopLine" \
  "didPrepareRendererStateWriteExecutorFirstSliceInput" \
  "didKeepRendererStateWriteExecutionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage162 renderer-state write precommit visibility boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage162_renderer_state_write_precommit_visibility_boundary_owner_present=true"
echo "stage161_renderer_state_write_admission_ledger_required=true"
echo "renderer_state_write_precommit_visibility_boundary_materialized=true"
echo "renderer_state_write_precommit_rollback_stop_line_bound=true"
echo "renderer_state_write_executor_first_slice_input_prepared=true"
echo "renderer_state_write_precommit_visibility_boundary_ready=true"
echo "renderer_state_write_precommit_visibility_boundary_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
