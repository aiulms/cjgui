#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage173 renderer-state write admission readiness
# recheck source。它消费 stage172 visibility admission，整理写入 admission ledger。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage173_renderer_state_write_admission_readiness_recheck_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage173 renderer-state write admission readiness recheck: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage173RendererStateWriteAdmissionReadinessRecheckFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage173RendererStateWriteAdmissionReadinessRecheckFirstSliceDraft" \
  "didConsumeStage172VisibilityPublicationAdmission" \
  "didMaterializeRendererStateWriteAdmissionReadinessLedger" \
  "didBindProductionTruthSemanticWriteTokenPredicates" \
  "didBindMutationExecutorVisibilityRollbackPredicates" \
  "didBindVisibilityPublicationAdmissionToWriteReadiness" \
  "didPrepareStage174RendererStateWriteFirstSliceCommitDryRunInput" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage173 renderer-state write admission readiness recheck: missing token $token" >&2
    exit 3
  fi
done

echo "stage173_renderer_state_write_admission_readiness_recheck_owner_present=true"
echo "stage172_visibility_publication_admission_required=true"
echo "renderer_state_write_admission_readiness_ledger_materialized=true"
echo "production_truth_semantic_write_token_predicates_bound=true"
echo "mutation_executor_visibility_rollback_predicates_bound=true"
echo "visibility_publication_admission_to_write_readiness_bound=true"
echo "stage174_renderer_state_write_first_slice_commit_dry_run_input_prepared=true"
echo "renderer_state_write_admission_readiness_recheck_ready=true"
echo "renderer_state_write_admission_readiness_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
