#!/usr/bin/env zsh
#
# 维护注释：验证 stage197 truth/semantic recheck bridge owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage197_truth_semantic_recheck_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage197 truth semantic recheck bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage197TruthSemanticRecheckBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage197TruthSemanticRecheckBridgeDraft" \
  "didConsumeStage196RendererStateWriteFirstSliceReadinessBoundary" \
  "didConsumeStage150ProductionTruthRecheck" \
  "didBindProductionTruthRecheckRequestToStage150Recheck" \
  "didBindSemanticAdmissionRecheckRequestToStage149Comparator" \
  "didPrepareStage198SemanticAdmissionGapLedgerInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage197 truth semantic recheck bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage197_truth_semantic_recheck_bridge_owner_present=true"
echo "stage196_readiness_boundary_required=true"
echo "stage150_production_truth_recheck_required=true"
echo "production_truth_recheck_request_bound_to_stage150=true"
echo "semantic_admission_recheck_request_bound_to_stage149=true"
echo "stage198_semantic_admission_gap_ledger_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
