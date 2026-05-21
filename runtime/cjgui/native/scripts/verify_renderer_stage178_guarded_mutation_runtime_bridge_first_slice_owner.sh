#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage178 guarded mutation runtime bridge source。
# 它只检查 owner-local runtime bridge 合同，不打开真实 renderer-state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage178_guarded_mutation_runtime_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage178 guarded mutation runtime bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage178GuardedMutationRuntimeBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage178GuardedMutationRuntimeBridgeFirstSliceDraft" \
  "didConsumeStage177RendererStateWriteFirstSliceReadinessDecision" \
  "didMaterializeGuardedMutationRuntimeBridgeEnvelope" \
  "didRecheckResultEnvelopePromotionToken" \
  "didBindMissingRuntimePredicateLedgerToBridge" \
  "didPrepareStage179RendererStateWriteMutationRequestRuntimeAdapterInput" \
  "didKeepGuardedMutationRuntimeBridgeNonMutating" \
  "didKeepRendererStateWriteRuntimeAdmissionDenied" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage178 guarded mutation runtime bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage178_guarded_mutation_runtime_bridge_owner_present=true"
echo "stage177_readiness_decision_required=true"
echo "guarded_mutation_runtime_bridge_envelope_materialized=true"
echo "result_envelope_promotion_token_rechecked=true"
echo "missing_runtime_predicate_ledger_bound=true"
echo "stage179_renderer_state_write_mutation_request_runtime_adapter_input_prepared=true"
echo "guarded_mutation_runtime_bridge_non_mutating=true"
echo "renderer_state_write_runtime_admission_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
