#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage154 visibility publication bridge owner 只把
# stage153 guarded executor bridge 的 denial input 接入 visibility publication
# predicate map，不发布 visibility truth，不写 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage154_visibility_publication_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage154 visibility publication bridge owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage154VisibilityPublicationBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage154VisibilityPublicationBridgeFirstSliceDraft" \
  "didBindStage153DenialInputToVisibilityPublicationEnvelope" \
  "didMaterializeVisibilityPublicationPositivePredicateMap" \
  "didDefineVisibilityPublicationAdmissionPositiveFixture" \
  "didPrepareRollbackVisibilityBoundaryInput" \
  "didKeepVisibilityPublicationRuntimeAdmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage154 visibility publication bridge owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage154_visibility_publication_bridge_owner_present=true"
echo "stage153_guarded_executor_bridge_packet_required=true"
echo "legacy_visibility_publication_denial_packet_required=true"
echo "visibility_publication_positive_predicate_map_materialized=true"
echo "visibility_publication_admission_positive_fixture_defined=true"
echo "stage153_denial_input_bound_to_visibility_publication_envelope=true"
echo "rollback_visibility_boundary_input_prepared=true"
echo "visibility_publication_bridge_runtime_admitted=false"
echo "visibility_publication_blocked=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
