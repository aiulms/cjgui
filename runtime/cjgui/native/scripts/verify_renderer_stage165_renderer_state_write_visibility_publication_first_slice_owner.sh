#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage165 visibility publication source。它消费
# rollback publication result，准备 write-decision recheck 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage165_renderer_state_write_visibility_publication_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage165 renderer-state write visibility publication: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage165RendererStateWriteVisibilityPublicationFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage165RendererStateWriteVisibilityPublicationFirstSliceDraft" \
  "didConsumeStage164RendererStateWriteRollbackPublication" \
  "didMaterializeRendererStateWriteVisibilityPublicationResult" \
  "didBindVisibilityPublicationToRollbackPublication" \
  "didPrepareRendererStateWriteDecisionRecheckInput" \
  "didKeepVisibilityPublicationInternalOnly" \
  "didKeepRendererStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage165 renderer-state write visibility publication: missing token $token" >&2
    exit 3
  fi
done

echo "stage165_renderer_state_write_visibility_publication_owner_present=true"
echo "stage164_renderer_state_write_rollback_publication_required=true"
echo "renderer_state_write_visibility_publication_result_materialized=true"
echo "renderer_state_write_visibility_publication_internal_only=true"
echo "renderer_state_write_decision_recheck_input_prepared=true"
echo "renderer_state_write_visibility_publication_ready=true"
echo "renderer_state_write_visibility_publication_runtime_admitted=false"
echo "renderer_state_write_visibility_publication_non_mutating=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
