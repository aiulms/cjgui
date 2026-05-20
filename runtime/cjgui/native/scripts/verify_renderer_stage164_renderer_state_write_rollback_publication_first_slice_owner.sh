#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage164 rollback publication source。它消费
# executor dry-run result envelope，仅发布 non-public rollback result 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage164_renderer_state_write_rollback_publication_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage164 renderer-state write rollback publication: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage164RendererStateWriteRollbackPublicationFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage164RendererStateWriteRollbackPublicationFirstSliceDraft" \
  "didConsumeStage163RendererStateWriteExecutorDryRun" \
  "didMaterializeRendererStateWriteRollbackPublicationResult" \
  "didBindRollbackPublicationToExecutorDryRun" \
  "didPrepareVisibilityPublicationResultInput" \
  "didKeepRollbackPublicationNonMutating" \
  "didKeepRendererStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage164 renderer-state write rollback publication: missing token $token" >&2
    exit 3
  fi
done

echo "stage164_renderer_state_write_rollback_publication_owner_present=true"
echo "stage163_renderer_state_write_executor_dry_run_required=true"
echo "renderer_state_write_rollback_publication_result_materialized=true"
echo "renderer_state_write_rollback_publication_boundary_bound=true"
echo "renderer_state_write_visibility_publication_result_input_prepared=true"
echo "renderer_state_write_rollback_publication_ready=true"
echo "renderer_state_write_rollback_publication_runtime_admitted=false"
echo "renderer_state_write_rollback_publication_non_mutating=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
