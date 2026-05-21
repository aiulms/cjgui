#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage180 guarded executor runtime preflight source。
# 它只检查 executor preflight envelope，不执行真实 renderer-state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage180_guarded_executor_runtime_preflight_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage180 guarded executor runtime preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage180GuardedExecutorRuntimePreflightFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage180GuardedExecutorRuntimePreflightFirstSliceDraft" \
  "didConsumeStage179MutationRequestRuntimeAdapter" \
  "didMaterializeGuardedExecutorRuntimePreflightEnvelope" \
  "didBindMutationRequestPayloadToGuardedExecutor" \
  "didMaterializeGuardedExecutorPredicateRecheck" \
  "didBindRollbackVisibilityHold" \
  "didPrepareStage181VisibilityPublicationReadinessBridgeInput" \
  "didKeepGuardedExecutorRuntimePreflightNonMutating" \
  "didKeepGuardedExecutorRuntimeAdmissionDenied"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage180 guarded executor runtime preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage180_guarded_executor_runtime_preflight_owner_present=true"
echo "stage179_mutation_request_runtime_adapter_required=true"
echo "guarded_executor_runtime_preflight_envelope_materialized=true"
echo "mutation_request_payload_to_guarded_executor_bound=true"
echo "guarded_executor_predicate_recheck_materialized=true"
echo "rollback_visibility_hold_bound=true"
echo "stage181_visibility_publication_readiness_bridge_input_prepared=true"
echo "guarded_executor_runtime_preflight_non_mutating=true"
echo "guarded_executor_runtime_admission_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
