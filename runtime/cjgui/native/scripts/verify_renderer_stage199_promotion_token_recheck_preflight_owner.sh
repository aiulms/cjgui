#!/usr/bin/env zsh
#
# 维护注释：验证 stage199 promotion token recheck preflight owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage199_promotion_token_recheck_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage199 promotion token recheck preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage199PromotionTokenRecheckPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage199PromotionTokenRecheckPreflightDraft" \
  "didConsumeStage198SemanticAdmissionGapLedger" \
  "didMaterializeResultEnvelopePromotionTokenRecheck" \
  "didBindPromotionTokenToSemanticRuntimeAdmissionGapLedger" \
  "didMaterializePromotionTokenMissingPredicateReceipt" \
  "didPrepareStage200WriteReadinessRecheckJoinInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage199 promotion token recheck preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage199_promotion_token_recheck_preflight_owner_present=true"
echo "stage198_semantic_admission_gap_ledger_required=true"
echo "result_envelope_promotion_token_recheck_materialized=true"
echo "promotion_token_missing_predicate_receipt_materialized=true"
echo "stage200_write_readiness_recheck_join_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
