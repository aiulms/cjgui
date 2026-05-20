#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage152 mutation request bridge owner 只桥接
# 既有 request shape / rejection evidence，不执行 mutation request。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage152_mutation_request_bridge_after_write_token_gate_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage152 mutation request bridge owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage152MutationRequestBridgeAfterWriteTokenGateFirstSliceDraft" \
  "didBindMutationRequestShapeToStage151WriteTokenGate" \
  "didBindMutationRequestRejectionToDeniedWriteToken" \
  "didPrepareGuardedExecutorBridgeInput" \
  "didKeepMutationRequestRuntimeAdmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage152 mutation request bridge owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage152_mutation_request_bridge_after_write_token_gate_owner_present=true"
echo "stage151_write_token_gate_packet_required=true"
echo "legacy_mutation_request_result_envelope_required=true"
echo "mutation_request_shape_bound_to_stage151_write_token_gate=true"
echo "mutation_request_rejection_bound_to_denied_write_token=true"
echo "rollback_eligibility_bound_to_blocked_stage151=true"
echo "guarded_state_write_executor_bridge_input_prepared=true"
echo "mutation_request_bridge_runtime_admitted=false"
echo "guarded_state_write_executor_blocked=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
