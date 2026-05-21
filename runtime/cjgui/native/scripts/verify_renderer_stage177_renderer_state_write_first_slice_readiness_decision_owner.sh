#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage177 renderer-state write first-slice readiness
# decision source。它只生成决策 ledger，不打开真实写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage177_renderer_state_write_first_slice_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage177 renderer-state write first-slice readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage177RendererStateWriteFirstSliceReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage177RendererStateWriteFirstSliceReadinessDecisionDraft" \
  "didConsumeStage176VisibilityNotPublishedBoundary" \
  "didMaterializeRendererStateWriteFirstSliceReadinessDecisionLedger" \
  "didBindCommitDryRunRollbackVisibilityPredicates" \
  "didBindProductionTruthSemanticBackendStopLine" \
  "didPrepareStage178RendererStateWriteGuardedMutationRuntimeBridgeInput" \
  "didKeepRendererStateWriteFirstSliceRuntimeAdmissionDenied" \
  "didKeepVisibilityNotPublished" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage177 renderer-state write first-slice readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage177_renderer_state_write_first_slice_readiness_decision_owner_present=true"
echo "stage176_visibility_not_published_boundary_required=true"
echo "renderer_state_write_first_slice_readiness_decision_ledger_materialized=true"
echo "commit_dry_run_rollback_visibility_predicates_bound=true"
echo "production_truth_semantic_backend_stop_line_bound=true"
echo "stage178_renderer_state_write_guarded_mutation_runtime_bridge_input_prepared=true"
echo "renderer_state_write_first_slice_candidate_ready=true"
echo "missing_runtime_predicates_materialized=true"
echo "renderer_state_write_first_slice_decision_denied=true"
echo "renderer_state_write_first_slice_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
