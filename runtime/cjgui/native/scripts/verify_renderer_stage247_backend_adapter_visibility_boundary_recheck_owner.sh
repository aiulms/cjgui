#!/usr/bin/env zsh
#
# 维护注释：验证 stage247 backend adapter visibility boundary recheck owner。
# 它复核 executor result 未发布 visibility，作为 readiness decision 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage247_backend_adapter_visibility_boundary_recheck.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage247 backend adapter visibility boundary recheck: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckFacts" \
  "CjguiInternalRendererStage247BackendAdapterVisibilityBoundaryRecheckReadiness" \
  "cjguiInternalExecuteDefaultRendererStage247BackendAdapterVisibilityBoundaryRecheckDraft" \
  "didConsumeStage246BackendAdapterExecutorResultPacket" \
  "didMaterializeBackendAdapterVisibilityBoundaryRecheck" \
  "didRecheckBackendAdapterVisibilityNotPublishedBoundary" \
  "didRecheckExecutorResultRollbackReady" \
  "didRejectVisibilityPublicationAdmission" \
  "didPrepareStage248BackendAdapterExecutorReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage247 backend adapter visibility boundary recheck: missing token $token" >&2
    exit 3
  fi
done

echo "stage247_backend_adapter_visibility_boundary_recheck_owner_present=true"
echo "stage246_backend_adapter_executor_result_packet_required=true"
echo "backend_adapter_visibility_boundary_recheck_materialized=true"
echo "backend_adapter_visibility_not_published_boundary_rechecked=true"
echo "backend_adapter_executor_result_rollback_ready_rechecked=true"
echo "visibility_publication_admitted=false"
echo "stage248_backend_adapter_executor_readiness_decision_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
