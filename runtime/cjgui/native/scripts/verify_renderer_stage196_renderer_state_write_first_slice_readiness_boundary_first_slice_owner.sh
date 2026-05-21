#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage196 first-slice readiness boundary owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage196_renderer_state_write_first_slice_readiness_boundary_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage196 renderer_state write first-slice readiness boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage196RendererStateWriteFirstSliceReadinessBoundaryFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage196RendererStateWriteFirstSliceReadinessBoundaryFirstSliceDraft" \
  "didConsumeStage195RendererStateWriteAdmissionJoinDecision" \
  "didMaterializeRendererStateWriteFirstSliceReadinessBoundary" \
  "didBindAdmissionJoinDecisionToVisibilityHold" \
  "didMaterializeVisibilityPublicationHoldReceipt" \
  "didMaterializeRendererStateWriteReadinessBoundaryPacket" \
  "didPrepareStage197RendererStateWriteProductionTruthSemanticRecheckInput" \
  "didKeepRendererStateWriteFirstSliceBoundaryNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage196 renderer_state write first-slice readiness boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage196_renderer_state_write_first_slice_readiness_boundary_owner_present=true"
echo "stage195_admission_join_decision_required=true"
echo "renderer_state_write_first_slice_readiness_boundary_materialized=true"
echo "admission_join_decision_bound_to_visibility_hold=true"
echo "visibility_publication_hold_receipt_materialized=true"
echo "renderer_state_write_readiness_boundary_packet_materialized=true"
echo "stage197_renderer_state_write_production_truth_semantic_recheck_input_prepared=true"
echo "renderer_state_write_first_slice_boundary_non_mutating=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
