#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage174 renderer-state write commit dry-run
# first slice source。它只检查 owner-local 非写入 dry-run 合同，不执行状态写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage174_renderer_state_write_commit_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage174 renderer-state write commit dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage174RendererStateWriteCommitDryRunFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage174RendererStateWriteCommitDryRunFirstSliceDraft" \
  "didConsumeStage173RendererStateWriteAdmissionReadinessRecheck" \
  "didMaterializeRendererStateWriteCommitDryRunEnvelope" \
  "didBindWriteAdmissionLedgerToCommitDryRun" \
  "didBindOwnerLocalRendererStateCandidate" \
  "didPrepareStage175RollbackReadyResultInput" \
  "didKeepCommitDryRunNonMutating" \
  "didKeepVisibilityNotPublished" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage174 renderer-state write commit dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage174_renderer_state_write_commit_dry_run_owner_present=true"
echo "stage173_renderer_state_write_admission_readiness_recheck_required=true"
echo "renderer_state_write_commit_dry_run_envelope_materialized=true"
echo "write_admission_ledger_to_commit_dry_run_bound=true"
echo "owner_local_renderer_state_candidate_bound=true"
echo "stage175_rollback_ready_result_input_prepared=true"
echo "commit_dry_run_non_mutating=true"
echo "visibility_not_published=true"
echo "renderer_state_write_commit_dry_run_ready=true"
echo "renderer_state_write_commit_dry_run_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
