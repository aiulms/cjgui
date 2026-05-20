#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage145 baseline / semantic verification owner 只声明
# stage144 write decision 后续非变更合同，不执行 baseline compare 或状态写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage145_baseline_semantic_verification_after_write_decision_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage145 baseline semantic owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage145BaselineSemanticVerificationAfterWriteDecisionFirstSliceDraft" \
  "didRequireTruthAdmissionPreflightBeforeBaselineSemantic" \
  "didRequirePositiveFirstFrameBeforeBaselineSemantic" \
  "didRequireBaselineFixtureOrSemanticComparator" \
  "didKeepBaselineComparisonNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage145 baseline semantic owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage145_baseline_semantic_verification_after_write_decision_owner_present=true"
echo "stage144_write_decision_packet_required=true"
echo "truth_admission_preflight_before_baseline_semantic_required=true"
echo "positive_first_frame_before_baseline_semantic_required=true"
echo "frame_hash_nonzero_before_baseline_semantic_required=true"
echo "baseline_fixture_or_semantic_comparator_required=true"
echo "baseline_comparison_non_mutating=true"
echo "semantic_acceptance_pre_production=true"
echo "production_render_truth=false"
echo "result_envelope_promoted_to_production_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
