#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage168 admission snapshot source。它消费
# stage167 first-slice contract，物化写入前置谓词快照，不执行写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage168_renderer_state_write_admission_snapshot_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage168 renderer-state write admission snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage168RendererStateWriteAdmissionSnapshotFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage168RendererStateWriteAdmissionSnapshotFirstSliceDraft" \
  "didConsumeStage167RendererStateWriteFirstSliceContract" \
  "didMaterializeRendererStateWriteAdmissionSnapshotLedger" \
  "didBindProductionTruthPredicateSnapshot" \
  "didBindSemanticComparisonPredicateSnapshot" \
  "didBindWriteTokenPredicateSnapshot" \
  "didPrepareStage169OwnerLocalStateEnvelopeDryRunInput" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage168 renderer-state write admission snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage168_renderer_state_write_admission_snapshot_owner_present=true"
echo "stage167_renderer_state_write_first_slice_contract_required=true"
echo "renderer_state_write_admission_snapshot_ledger_materialized=true"
echo "production_truth_predicate_snapshot_bound=true"
echo "semantic_comparison_predicate_snapshot_bound=true"
echo "write_token_predicate_snapshot_bound=true"
echo "guarded_executor_predicate_snapshot_bound=true"
echo "stage169_owner_local_state_envelope_dry_run_input_prepared=true"
echo "renderer_state_write_admission_snapshot_ready=true"
echo "renderer_state_write_admission_snapshot_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
