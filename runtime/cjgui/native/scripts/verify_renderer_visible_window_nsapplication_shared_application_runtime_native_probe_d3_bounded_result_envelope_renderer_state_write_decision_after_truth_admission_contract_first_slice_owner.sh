#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage144 renderer-state write decision owner 只声明
# non-mutating write decision，不执行 renderer state 或 runtime_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_after_truth_admission_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage144 renderer-state write decision owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionAfterTruthAdmissionContractFirstSliceDraft" \
  "didRequireProductionRenderTruthBeforeRendererStateWrite" \
  "didRequireBackendReadyTruthBeforeRendererStateWrite" \
  "didRequireProductionWriteAdmissionBeforeRendererStateWrite" \
  "didKeepWriteDecisionNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage144 renderer-state write decision owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage144_renderer_state_write_decision_after_truth_admission_contract_owner_present=true"
echo "stage143_truth_admission_packet_required=true"
echo "truth_admission_preflight_before_write_decision_required=true"
echo "production_render_truth_before_renderer_state_write_required=true"
echo "backend_ready_truth_before_renderer_state_write_required=true"
echo "production_write_admission_before_renderer_state_write_required=true"
echo "state_mutation_request_envelope_before_write_required=true"
echo "renderer_state_write_decision_non_mutating=true"
echo "renderer_state_write_allowed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
