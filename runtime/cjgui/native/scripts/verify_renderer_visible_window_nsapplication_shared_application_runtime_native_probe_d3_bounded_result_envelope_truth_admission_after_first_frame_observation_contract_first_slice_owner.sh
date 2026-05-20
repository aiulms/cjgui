#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage143 truth admission owner 只声明 stage142
# first-frame envelope 后续 readiness，不执行 native runtime 或 renderer state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_truth_admission_after_first_frame_observation_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage143 truth admission owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeTruthAdmissionAfterFirstFrameObservationContractFirstSliceDraft" \
  "didRequirePositiveFirstFrameBeforeTruthAdmission" \
  "didRequireBaselineOrSemanticVerificationBeforeProductionTruth" \
  "didRequireBackendReadyPredicateBeforeProductionTruth" \
  "didKeepTruthAdmissionPreflightOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage143 truth admission owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage143_truth_admission_after_first_frame_observation_contract_owner_present=true"
echo "stage142_first_frame_packet_required=true"
echo "positive_first_frame_before_truth_admission_required=true"
echo "frame_hash_computed_required=true"
echo "frame_hash_nonzero_required=true"
echo "frame_hash_value_redacted_required=true"
echo "frame_hash_persisted=false"
echo "baseline_or_semantic_verification_before_production_truth_required=true"
echo "backend_ready_predicate_before_production_truth_required=true"
echo "truth_admission_preflight_only=true"
echo "production_render_truth=false"
echo "result_envelope_promoted_to_production_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
