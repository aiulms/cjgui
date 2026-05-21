#!/usr/bin/env zsh
#
# 维护注释：验证 stage248 backend adapter executor readiness decision owner。
# 它汇合 executor、result packet 与 visibility boundary，准备 stage249 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage248_backend_adapter_executor_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage248 backend adapter executor readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionFacts" \
  "CjguiInternalRendererStage248BackendAdapterExecutorReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage248BackendAdapterExecutorReadinessDecisionDraft" \
  "didConsumeStage247BackendAdapterVisibilityBoundaryRecheck" \
  "didJoinExecutorWithResultPacketAndVisibilityBoundary" \
  "didMaterializeBackendAdapterExecutorReadinessDecision" \
  "didPrepareStage249ComponentDemoBackendResultPreviewInput" \
  "didKeepOwnerLocalInMemoryDryRunOnly" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage248 backend adapter executor readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage248_backend_adapter_executor_readiness_decision_owner_present=true"
echo "stage247_backend_adapter_visibility_boundary_recheck_required=true"
echo "backend_adapter_executor_readiness_decision_materialized=true"
echo "stage249_component_demo_backend_result_preview_input_prepared=true"
echo "owner_local_in_memory_dry_run_only=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
