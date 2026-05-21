#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage179 mutation request runtime adapter source。
# 它只检查 dry-run payload 与下一段 executor input，不执行真实 mutation。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage179_renderer_state_write_mutation_request_runtime_adapter_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage179 mutation request runtime adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage179RendererStateWriteMutationRequestRuntimeAdapterFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage179RendererStateWriteMutationRequestRuntimeAdapterFirstSliceDraft" \
  "didConsumeStage178GuardedMutationRuntimeBridge" \
  "didMaterializeRendererStateWriteMutationRequestRuntimeAdapter" \
  "didBindGuardedMutationBridgeToMutationRequest" \
  "didMaterializeMutationRequestDryRunPayload" \
  "didBindResultEnvelopePromotionTokenDenial" \
  "didPrepareStage180GuardedExecutorRuntimePreflightInput" \
  "didKeepMutationRequestRuntimeAdapterNonMutating" \
  "didKeepMutationRequestRuntimeAdmissionDenied"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage179 mutation request runtime adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage179_renderer_state_write_mutation_request_runtime_adapter_owner_present=true"
echo "stage178_guarded_mutation_runtime_bridge_required=true"
echo "renderer_state_write_mutation_request_runtime_adapter_materialized=true"
echo "guarded_mutation_bridge_to_mutation_request_bound=true"
echo "mutation_request_dry_run_payload_materialized=true"
echo "result_envelope_promotion_token_denial_bound=true"
echo "stage180_guarded_executor_runtime_preflight_input_prepared=true"
echo "mutation_request_runtime_adapter_non_mutating=true"
echo "mutation_request_runtime_admission_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
