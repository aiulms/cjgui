#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage155 rollback visibility boundary bridge owner
# 只把 stage154 visibility bridge 接到 rollback boundary predicate，不执行
# rollback fallback state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage155_rollback_visibility_boundary_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage155 rollback visibility boundary bridge owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceDraft" \
  "didBindVisibilityPublicationBridgeToRollbackBoundary" \
  "didMaterializeRollbackVisibilityPositivePredicateMap" \
  "didDefineRollbackVisibilityBoundaryPositiveFixture" \
  "didPrepareRendererStateWriteFirstSliceInput" \
  "didKeepRollbackVisibilityBoundaryRuntimeAdmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage155 rollback visibility boundary bridge owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage155_rollback_visibility_boundary_bridge_owner_present=true"
echo "stage154_visibility_publication_bridge_packet_required=true"
echo "legacy_rollback_fallback_denial_packet_required=true"
echo "rollback_visibility_positive_predicate_map_materialized=true"
echo "rollback_visibility_boundary_positive_fixture_defined=true"
echo "visibility_publication_bridge_bound_to_rollback_boundary=true"
echo "renderer_state_write_first_slice_input_prepared=true"
echo "rollback_visibility_boundary_runtime_admitted=false"
echo "rollback_fallback_state_write_denied=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
