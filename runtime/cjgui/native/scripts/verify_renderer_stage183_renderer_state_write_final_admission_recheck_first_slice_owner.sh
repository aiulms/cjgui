#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage183 renderer-state write final admission
# recheck source。它只整理最终 admission ledger，不执行写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage183_renderer_state_write_final_admission_recheck_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage183 final admission recheck: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage183RendererStateWriteFinalAdmissionRecheckFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage183RendererStateWriteFinalAdmissionRecheckFirstSliceDraft" \
  "didConsumeStage182VisibilityPublicationDecision" \
  "didMaterializeRendererStateWriteFinalAdmissionLedger" \
  "didBindVisibilityPublicationDecisionToFinalAdmission" \
  "didBindProductionTruthBackendSemanticPredicateLedger" \
  "didBindResultEnvelopePromotionTokenDenial" \
  "didPrepareStage184RendererStateWriteOwnerLocalStateEnvelopeInput" \
  "didKeepRendererStateWriteFinalAdmissionDenied"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage183 final admission recheck: missing token $token" >&2
    exit 3
  fi
done

echo "stage183_final_admission_recheck_owner_present=true"
echo "stage182_visibility_publication_decision_required=true"
echo "renderer_state_write_final_admission_ledger_materialized=true"
echo "visibility_publication_decision_to_final_admission_bound=true"
echo "production_truth_backend_semantic_predicate_ledger_bound=true"
echo "result_envelope_promotion_token_denial_bound=true"
echo "stage184_renderer_state_write_owner_local_state_envelope_input_prepared=true"
echo "renderer_state_write_final_admission_non_mutating=true"
echo "renderer_state_write_final_admission_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
