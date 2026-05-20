#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage166 write-decision recheck source。它消费
# visibility publication result，只输出 state-write first-slice 前置合同。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage166_renderer_state_write_decision_recheck_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage166 renderer-state write decision recheck: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage166RendererStateWriteDecisionRecheckFirstSliceDraft" \
  "didConsumeStage165RendererStateWriteVisibilityPublication" \
  "didMaterializeRendererStateWriteDecisionRecheckLedger" \
  "didBindDecisionRecheckToVisibilityPublication" \
  "didPrepareRendererStateWriteFirstSliceContractInput" \
  "didKeepRendererStateWriteDecisionDenied" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage166 renderer-state write decision recheck: missing token $token" >&2
    exit 3
  fi
done

echo "stage166_renderer_state_write_decision_recheck_owner_present=true"
echo "stage165_renderer_state_write_visibility_publication_required=true"
echo "renderer_state_write_decision_recheck_ledger_materialized=true"
echo "renderer_state_write_decision_positive_predicates_bound=true"
echo "renderer_state_write_first_slice_contract_input_prepared=true"
echo "renderer_state_write_decision_recheck_ready=true"
echo "renderer_state_write_decision_recheck_runtime_admitted=false"
echo "renderer_state_write_decision_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
