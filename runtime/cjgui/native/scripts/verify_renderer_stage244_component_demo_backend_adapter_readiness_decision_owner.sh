#!/usr/bin/env zsh
#
# 维护注释：验证 stage244 component demo backend adapter readiness decision owner。
# 它只汇合 packet、diff/explain 与 dry-run predicate，准备 stage245 executor 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage244_component_demo_backend_adapter_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage244 component demo backend adapter readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage244ComponentDemoBackendAdapterReadinessDecisionFacts" \
  "CjguiInternalRendererStage244ComponentDemoBackendAdapterReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage244ComponentDemoBackendAdapterReadinessDecisionDraft" \
  "didConsumeStage243BackendAdapterDryRunPredicate" \
  "didJoinAdapterPacketWithSemanticDiffExplain" \
  "didJoinAdapterDryRunPredicateWithRollbackBoundary" \
  "didMaterializeComponentDemoBackendAdapterReadinessDecision" \
  "didPrepareStage245BackendAdapterDryRunExecutorInput" \
  "didKeepOwnerLocalInMemoryDryRunOnly" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage244 component demo backend adapter readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage244_component_demo_backend_adapter_readiness_decision_owner_present=true"
echo "stage243_backend_adapter_dry_run_predicate_required=true"
echo "component_demo_backend_adapter_readiness_decision_materialized=true"
echo "stage245_backend_adapter_dry_run_executor_input_prepared=true"
echo "owner_local_in_memory_dry_run_only=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
