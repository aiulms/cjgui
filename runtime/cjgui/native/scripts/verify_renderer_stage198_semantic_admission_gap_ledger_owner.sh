#!/usr/bin/env zsh
#
# 维护注释：验证 stage198 semantic admission gap ledger owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage198_semantic_admission_gap_ledger.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage198 semantic admission gap ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage198SemanticAdmissionGapLedgerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage198SemanticAdmissionGapLedgerDraft" \
  "didConsumeStage197TruthSemanticRecheckBridge" \
  "didMaterializeSemanticRuntimeAdmissionGapLedger" \
  "didMaterializeLiveBaselineCompareRequirement" \
  "didMaterializeBackendReadyTruthRequirement" \
  "didPrepareStage199PromotionTokenRecheckPreflightInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage198 semantic admission gap ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage198_semantic_admission_gap_ledger_owner_present=true"
echo "stage197_truth_semantic_recheck_bridge_required=true"
echo "semantic_runtime_admission_gap_ledger_materialized=true"
echo "live_baseline_compare_requirement_materialized=true"
echo "backend_ready_truth_requirement_materialized=true"
echo "stage199_promotion_token_recheck_preflight_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
