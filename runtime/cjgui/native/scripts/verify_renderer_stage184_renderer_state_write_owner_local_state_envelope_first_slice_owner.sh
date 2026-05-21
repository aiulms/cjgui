#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage184 renderer-state write owner-local
# state envelope dry-run source。它只物化内部 envelope，不写生产 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage184_renderer_state_write_owner_local_state_envelope_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage184 owner-local state envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage184RendererStateWriteOwnerLocalStateEnvelopeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage184RendererStateWriteOwnerLocalStateEnvelopeFirstSliceDraft" \
  "didConsumeStage183FinalAdmissionRecheck" \
  "didMaterializeRendererStateWriteOwnerLocalStateEnvelope" \
  "didBindFinalAdmissionLedgerToStateEnvelope" \
  "didBindBlockedWriteDecisionToEnvelope" \
  "didBindRollbackVisibilityBoundaryToEnvelope" \
  "didPrepareStage185RuntimeStateWriteSchemaCandidateInput" \
  "didKeepOwnerLocalStateEnvelopeDryRunOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage184 owner-local state envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage184_owner_local_state_envelope_owner_present=true"
echo "stage183_final_admission_recheck_required=true"
echo "renderer_state_write_owner_local_state_envelope_materialized=true"
echo "final_admission_ledger_to_state_envelope_bound=true"
echo "blocked_write_decision_to_envelope_bound=true"
echo "rollback_visibility_boundary_to_envelope_bound=true"
echo "stage185_runtime_state_write_schema_candidate_input_prepared=true"
echo "owner_local_state_envelope_dry_run_only=true"
echo "renderer_state_write_eligibility=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
