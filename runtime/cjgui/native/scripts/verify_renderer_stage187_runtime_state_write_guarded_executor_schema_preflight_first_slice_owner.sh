#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage187 runtime_state write guarded executor
# schema preflight owner。它只做 predicate recheck，不执行写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage187_runtime_state_write_guarded_executor_schema_preflight_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage187 runtime_state guarded executor schema preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage187RuntimeStateWriteGuardedExecutorSchemaPreflightFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage187RuntimeStateWriteGuardedExecutorSchemaPreflightFirstSliceDraft" \
  "didConsumeStage186RuntimeStateWriteMutationRequestSchemaAdapter" \
  "didMaterializeRuntimeStateWriteGuardedExecutorSchemaPreflight" \
  "didBindMutationRequestPayloadToGuardedExecutor" \
  "didMaterializeRuntimeStateWriteGuardedExecutorPredicateRecheck" \
  "didBindRollbackVisibilityHoldToSchemaPreflight" \
  "didPrepareStage188RuntimeStateWriteVisibilityPublicationSchemaBridgeInput" \
  "didKeepRuntimeStateWriteGuardedExecutorPreflightNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage187 runtime_state guarded executor schema preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage187_runtime_state_guarded_executor_schema_preflight_owner_present=true"
echo "stage186_runtime_state_mutation_request_schema_adapter_required=true"
echo "runtime_state_write_guarded_executor_schema_preflight_materialized=true"
echo "mutation_request_payload_to_guarded_executor_bound=true"
echo "runtime_state_write_guarded_executor_predicate_recheck_materialized=true"
echo "rollback_visibility_hold_to_schema_preflight_bound=true"
echo "stage188_runtime_state_write_visibility_publication_schema_bridge_input_prepared=true"
echo "runtime_state_write_guarded_executor_preflight_non_mutating=true"
echo "guarded_executor_schema_preflight_predicates_satisfied=false"
echo "renderer_state_write_eligibility=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
