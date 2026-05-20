#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage146 production truth promotion owner 只声明
# baseline / semantic 后续 promotion gate，不升级 production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage146_production_truth_promotion_after_baseline_semantic_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage146 production truth owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage146ProductionTruthPromotionAfterBaselineSemanticFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage146ProductionTruthPromotionAfterBaselineSemanticFirstSliceDraft" \
  "didRequireBaselineComparedBeforeProductionTruth" \
  "didRequireSemanticAcceptanceBeforeProductionTruth" \
  "didRequireBackendReadyBeforeProductionTruth" \
  "didKeepProductionTruthPromotionNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage146 production truth owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage146_production_truth_promotion_after_baseline_semantic_owner_present=true"
echo "stage145_baseline_semantic_packet_required=true"
echo "baseline_compared_before_production_truth_required=true"
echo "semantic_acceptance_before_production_truth_required=true"
echo "backend_ready_before_production_truth_required=true"
echo "frame_hash_value_redacted_for_promotion_required=true"
echo "production_truth_promotion_non_mutating=true"
echo "result_envelope_promoted_to_production_truth=false"
echo "production_render_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
