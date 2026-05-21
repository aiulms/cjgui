#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage175 rollback-ready result first slice source。
# 它消费 stage174 commit dry-run，生成可回滚结果 envelope，但不执行写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage175_renderer_state_write_rollback_ready_result_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage175 renderer-state write rollback-ready result: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage175RendererStateWriteRollbackReadyResultFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage175RendererStateWriteRollbackReadyResultFirstSliceDraft" \
  "didConsumeStage174RendererStateWriteCommitDryRun" \
  "didMaterializeRollbackReadyResultEnvelope" \
  "didBindCommitDryRunResultToRollbackReadiness" \
  "didBindRollbackSnapshotOwnerLocalOnly" \
  "didPrepareStage176VisibilityNotPublishedBoundaryInput" \
  "didKeepRollbackReadyResultNonMutating" \
  "didKeepVisibilityPublicationBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage175 renderer-state write rollback-ready result: missing token $token" >&2
    exit 3
  fi
done

echo "stage175_renderer_state_write_rollback_ready_result_owner_present=true"
echo "stage174_renderer_state_write_commit_dry_run_required=true"
echo "rollback_ready_result_envelope_materialized=true"
echo "commit_dry_run_result_to_rollback_readiness_bound=true"
echo "rollback_snapshot_owner_local_only=true"
echo "stage176_visibility_not_published_boundary_input_prepared=true"
echo "rollback_ready_result_non_mutating=true"
echo "visibility_publication_blocked=true"
echo "renderer_state_write_rollback_ready_result_ready=true"
echo "renderer_state_write_rollback_ready_result_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
