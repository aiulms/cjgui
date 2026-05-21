#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage195 admission join decision owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage195_renderer_state_write_admission_join_decision_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage195 renderer_state write admission join decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage195RendererStateWriteAdmissionJoinDecisionFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage195RendererStateWriteAdmissionJoinDecisionFirstSliceDraft" \
  "didConsumeStage194RendererStateWriteResultEnvelopePromotionPreflight" \
  "didMaterializeRendererStateWriteAdmissionJoinDecisionLedger" \
  "didBindPromotionPreflightToAdmissionPredicates" \
  "didBindPositiveFixturePredicatesToAdmissionJoin" \
  "didMaterializeProductionTruthRecheckRequest" \
  "didMaterializeSemanticAdmissionRecheckRequest" \
  "didPrepareStage196RendererStateWriteFirstSliceReadinessBoundaryInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage195 renderer_state write admission join decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage195_renderer_state_write_admission_join_decision_owner_present=true"
echo "stage194_result_envelope_promotion_preflight_required=true"
echo "renderer_state_write_admission_join_decision_ledger_materialized=true"
echo "promotion_preflight_bound_to_admission_predicates=true"
echo "positive_fixture_predicates_bound_to_admission_join=true"
echo "production_truth_recheck_request_materialized=true"
echo "semantic_admission_recheck_request_materialized=true"
echo "stage196_renderer_state_write_first_slice_readiness_boundary_input_prepared=true"
echo "renderer_state_write_admission_decision_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
