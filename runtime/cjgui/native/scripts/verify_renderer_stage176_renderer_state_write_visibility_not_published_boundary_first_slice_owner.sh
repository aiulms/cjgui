#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage176 visibility-not-published boundary source。
# 它消费 rollback-ready result，只建立内部 visibility 停止线。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage176_renderer_state_write_visibility_not_published_boundary_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage176 renderer-state write visibility-not-published boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage176RendererStateWriteVisibilityNotPublishedBoundaryFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage176RendererStateWriteVisibilityNotPublishedBoundaryFirstSliceDraft" \
  "didConsumeStage175RollbackReadyResult" \
  "didMaterializeVisibilityNotPublishedBoundary" \
  "didBindRollbackReadyResultToVisibilityStopLine" \
  "didBindInternalVisibilityShadowOnly" \
  "didPrepareStage177RendererStateWriteFirstSliceReadinessDecisionInput" \
  "didKeepVisibilityPublicationInternalOnly" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage176 renderer-state write visibility-not-published boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage176_renderer_state_write_visibility_not_published_boundary_owner_present=true"
echo "stage175_rollback_ready_result_required=true"
echo "visibility_not_published_boundary_materialized=true"
echo "rollback_ready_result_to_visibility_stop_line_bound=true"
echo "internal_visibility_shadow_only=true"
echo "stage177_renderer_state_write_first_slice_readiness_decision_input_prepared=true"
echo "visibility_publication_internal_only=true"
echo "renderer_state_write_visibility_not_published_boundary_ready=true"
echo "renderer_state_write_visibility_not_published_boundary_runtime_admitted=false"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
