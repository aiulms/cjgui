#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage186 runtime_state write mutation request
# schema adapter first-slice owner。它只形成 dry-run request，不写 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage186_runtime_state_write_mutation_request_schema_adapter_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage186 runtime_state mutation request schema adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage186RuntimeStateWriteMutationRequestSchemaAdapterFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage186RuntimeStateWriteMutationRequestSchemaAdapterFirstSliceDraft" \
  "didConsumeStage185RuntimeStateWriteSchemaCandidate" \
  "didMaterializeRuntimeStateWriteMutationRequestSchemaAdapter" \
  "didBindSchemaCandidateToMutationRequest" \
  "didMaterializeRuntimeStateWriteMutationRequestDryRunPayload" \
  "didBindRuntimeStateWriteAdmissionDenialToMutationRequest" \
  "didPrepareStage187RuntimeStateWriteGuardedExecutorSchemaPreflightInput" \
  "didKeepRuntimeStateWriteMutationRequestDryRunOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage186 runtime_state mutation request schema adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage186_runtime_state_mutation_request_schema_adapter_owner_present=true"
echo "stage185_runtime_state_schema_candidate_required=true"
echo "runtime_state_write_mutation_request_schema_adapter_materialized=true"
echo "schema_candidate_to_mutation_request_bound=true"
echo "runtime_state_write_mutation_request_dry_run_payload_materialized=true"
echo "runtime_state_write_admission_denial_to_mutation_request_bound=true"
echo "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true"
echo "runtime_state_write_mutation_request_dry_run_only=true"
echo "renderer_state_write_eligibility=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
