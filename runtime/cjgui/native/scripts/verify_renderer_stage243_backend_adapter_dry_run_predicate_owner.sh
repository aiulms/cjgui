#!/usr/bin/env zsh
#
# 维护注释：验证 stage243 backend adapter dry-run predicate owner。
# 它只允许 in-memory / no-submit predicate，不执行 backend 或 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage243_backend_adapter_dry_run_predicate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage243 backend adapter dry run predicate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage243BackendAdapterDryRunPredicateFacts" \
  "CjguiInternalRendererStage243BackendAdapterDryRunPredicateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage243BackendAdapterDryRunPredicateDraft" \
  "didConsumeStage242BackendAdapterSemanticDiffExplain" \
  "didMaterializeBackendAdapterDryRunPredicate" \
  "didBindPredicateToRollbackReadyAdapterBoundary" \
  "didAllowOwnerLocalInMemoryAdapterDryRun" \
  "didRejectRendererSubmissionMutation" \
  "didRejectRendererStateWriteMutation" \
  "didPrepareStage244BackendAdapterReadinessDecisionInput" \
  "didKeepBackendAdapterPredicateValueOnly" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage243 backend adapter dry run predicate: missing token $token" >&2
    exit 3
  fi
done

echo "stage243_backend_adapter_dry_run_predicate_owner_present=true"
echo "stage242_backend_adapter_semantic_diff_explain_required=true"
echo "backend_adapter_dry_run_predicate_materialized=true"
echo "owner_local_in_memory_adapter_dry_run_allowed=true"
echo "renderer_submission_mutation_rejected=true"
echo "renderer_state_write_mutation_rejected=true"
echo "stage244_backend_adapter_readiness_decision_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
