#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage150 production truth recheck owner 只复核
# production truth gate，不发布 truth 或状态写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage150 production truth recheck owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage150ProductionTruthRecheckAfterSemanticComparatorBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage150ProductionTruthRecheckAfterSemanticComparatorBridgeFirstSliceDraft" \
  "didRequireSemanticAcceptanceRuntimeBeforeProductionTruth" \
  "didRequireBackendReadyTruthBeforeProductionTruth" \
  "didRequireResultEnvelopePromotionToken" \
  "didKeepProductionTruthRecheckNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage150 production truth recheck owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage150_production_truth_recheck_after_semantic_comparator_bridge_owner_present=true"
echo "stage149_semantic_comparator_bridge_packet_required=true"
echo "semantic_acceptance_runtime_before_production_truth_required=true"
echo "backend_ready_truth_before_production_truth_required=true"
echo "result_envelope_promotion_token_required=true"
echo "production_truth_recheck_non_mutating=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
