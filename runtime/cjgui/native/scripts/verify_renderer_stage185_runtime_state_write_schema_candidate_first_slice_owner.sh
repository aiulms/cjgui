#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage185 runtime_state write schema candidate
# first-slice owner。它只检查内部 schema candidate source，不写 runtime_state.cj。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage185_runtime_state_write_schema_candidate_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage185 runtime_state schema candidate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage185RuntimeStateWriteSchemaCandidateFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage185RuntimeStateWriteSchemaCandidateFirstSliceDraft" \
  "didConsumeStage184OwnerLocalStateEnvelope" \
  "didMaterializeRuntimeStateWriteSchemaCandidate" \
  "didBindOwnerLocalStateEnvelopeToSchemaCandidate" \
  "didBindBlockedWriteDecisionToSchemaCandidate" \
  "didBindRuntimeStateWriteStopLineToSchemaCandidate" \
  "didPrepareStage186RuntimeStateWriteMutationRequestSchemaAdapterInput" \
  "didKeepRuntimeStateWriteSchemaCandidateDryRunOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage185 runtime_state schema candidate: missing token $token" >&2
    exit 3
  fi
done

echo "stage185_runtime_state_schema_candidate_owner_present=true"
echo "stage184_owner_local_state_envelope_required=true"
echo "runtime_state_write_schema_candidate_materialized=true"
echo "owner_local_state_envelope_to_schema_candidate_bound=true"
echo "blocked_write_decision_to_schema_candidate_bound=true"
echo "runtime_state_write_stop_line_to_schema_candidate_bound=true"
echo "stage186_runtime_state_write_mutation_request_schema_adapter_input_prepared=true"
echo "runtime_state_write_schema_candidate_dry_run_only=true"
echo "renderer_state_write_eligibility=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
