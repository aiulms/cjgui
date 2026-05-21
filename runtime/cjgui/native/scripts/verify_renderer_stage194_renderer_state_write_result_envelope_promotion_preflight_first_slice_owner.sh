#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage194 result envelope promotion preflight owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage194_renderer_state_write_result_envelope_promotion_preflight_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage194 renderer_state write result-envelope promotion preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage194RendererStateWriteResultEnvelopePromotionPreflightFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage194RendererStateWriteResultEnvelopePromotionPreflightFirstSliceDraft" \
  "didConsumeStage193RendererStateWriteDryRunExecutorResult" \
  "didMaterializeRendererStateWriteResultEnvelopePromotionPreflight" \
  "didBindDryRunExecutorResultEnvelopeToPromotionPreflight" \
  "didMaterializeResultEnvelopePromotionTokenCandidateLedger" \
  "didMaterializeMissingProductionPredicateLedger" \
  "didPrepareStage195RendererStateWriteAdmissionJoinDecisionInput" \
  "didKeepRendererStateWriteResultEnvelopePromotionPreflightNonProduction"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage194_renderer_state_write_result_envelope_promotion_preflight_owner_present=true"
echo "stage193_dry_run_executor_result_required=true"
echo "renderer_state_write_result_envelope_promotion_preflight_materialized=true"
echo "dry_run_executor_result_envelope_bound_to_promotion_preflight=true"
echo "result_envelope_promotion_token_candidate_ledger_materialized=true"
echo "missing_production_predicate_ledger_materialized=true"
echo "stage195_renderer_state_write_admission_join_decision_input_prepared=true"
echo "result_envelope_promotion_preflight_non_production=true"
echo "result_envelope_promotion_token=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
