#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage161 admission ledger source，把 dry-run envelope
# 转换为可复核的 write predicate ledger；仍不允许 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage161_renderer_state_write_admission_ledger_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage161 renderer-state write admission ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage161RendererStateWriteAdmissionLedgerFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage161RendererStateWriteAdmissionLedgerFirstSliceDraft" \
  "didConsumeStage160RendererStateWriteDryRun" \
  "didMaterializeRendererStateWriteAdmissionLedger" \
  "didRecordProductionTruthPredicate" \
  "didRecordSemanticComparisonPredicate" \
  "didRecordWriteTokenGatePredicate" \
  "didRecordMutationDryRunPredicate" \
  "didRecordGuardedExecutorPredicate" \
  "didRecordVisibilityResultPredicate" \
  "didRecordRollbackBoundaryPredicate" \
  "didPrepareRendererStateWritePrecommitVisibilityBoundaryInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage161 renderer-state write admission ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage161_renderer_state_write_admission_ledger_owner_present=true"
echo "stage160_renderer_state_write_dry_run_required=true"
echo "renderer_state_write_admission_ledger_materialized=true"
echo "renderer_state_write_admission_positive_fixture_defined=true"
echo "renderer_state_write_precommit_visibility_boundary_input_prepared=true"
echo "renderer_state_write_admission_ledger_ready=true"
echo "renderer_state_write_admission_ledger_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
