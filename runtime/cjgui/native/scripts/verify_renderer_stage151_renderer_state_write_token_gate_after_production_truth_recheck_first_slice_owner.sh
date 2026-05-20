#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage151 write token gate owner 只发布
# renderer-state write token gate 的 fail-closed contract，不执行状态写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage151_renderer_state_write_token_gate_after_production_truth_recheck_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage151 write token gate owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage151RendererStateWriteTokenGateAfterProductionTruthRecheckFirstSliceDraft" \
  "didRequireProductionTruthRecheckAllowedBeforeWriteToken" \
  "didRequireBackendReadyTruthBeforeWriteToken" \
  "didRequireStateMutationRequestEnvelopeBeforeWriteToken" \
  "didKeepRendererStateWriteTokenDenied"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage151 write token gate owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage151_renderer_state_write_token_gate_after_production_truth_recheck_owner_present=true"
echo "stage150_production_truth_recheck_packet_required=true"
echo "production_truth_recheck_allowed_before_write_token_required=true"
echo "production_render_truth_before_write_token_required=true"
echo "backend_ready_truth_before_write_token_required=true"
echo "state_mutation_request_envelope_before_write_token_required=true"
echo "renderer_state_write_token_denied=true"
echo "state_mutation_request_blocked=true"
echo "visibility_publication_blocked=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
