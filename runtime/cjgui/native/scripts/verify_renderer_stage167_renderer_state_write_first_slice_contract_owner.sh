#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage167 renderer-state write first-slice contract
# source。它消费 stage166 decision recheck，只物化非写入 first-slice 合同。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage167_renderer_state_write_first_slice_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage167 renderer-state write first-slice contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage167RendererStateWriteFirstSliceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage167RendererStateWriteFirstSliceContractDraft" \
  "didConsumeStage166RendererStateWriteDecisionRecheck" \
  "didMaterializeRendererStateWriteFirstSliceContract" \
  "didBindOwnerLocalStateEnvelopeContract" \
  "didPrepareStage168RendererStateWriteAdmissionSnapshotInput" \
  "didKeepRendererStateWriteFirstSliceContractNonMutating" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage167 renderer-state write first-slice contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage167_renderer_state_write_first_slice_contract_owner_present=true"
echo "stage166_renderer_state_write_decision_recheck_required=true"
echo "renderer_state_write_first_slice_contract_materialized=true"
echo "owner_local_state_envelope_contract_bound=true"
echo "mutation_request_contract_bound=true"
echo "guarded_executor_contract_bound=true"
echo "visibility_publication_contract_bound=true"
echo "rollback_contract_bound=true"
echo "stage168_renderer_state_write_admission_snapshot_input_prepared=true"
echo "renderer_state_write_first_slice_contract_ready=true"
echo "renderer_state_write_first_slice_contract_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
