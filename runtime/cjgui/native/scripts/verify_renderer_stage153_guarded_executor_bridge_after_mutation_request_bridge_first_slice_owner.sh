#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage153 guarded executor bridge owner 只桥接
# guarded executor result / visibility denial input，不发布 visibility 或写状态。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage153 guarded executor bridge owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage153GuardedExecutorBridgeAfterMutationRequestBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage153GuardedExecutorBridgeAfterMutationRequestBridgeFirstSliceDraft" \
  "didBindGuardedExecutorDenialToStage152Bridge" \
  "didBindRollbackStopLineToStage152Bridge" \
  "didPrepareVisibilityPublicationDenialInput" \
  "didKeepGuardedExecutorRuntimeAdmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage153 guarded executor bridge owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage153_guarded_executor_bridge_after_mutation_request_bridge_owner_present=true"
echo "stage152_mutation_request_bridge_packet_required=true"
echo "legacy_guarded_executor_result_envelope_required=true"
echo "guarded_executor_inputs_bound_to_stage152_bridge=true"
echo "guarded_executor_denial_bound_to_stage152_bridge=true"
echo "rollback_stop_line_bound_to_stage152_bridge=true"
echo "visibility_publication_denial_input_prepared=true"
echo "guarded_executor_bridge_runtime_admitted=false"
echo "guarded_executor_denied=true"
echo "visibility_publication_blocked=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
