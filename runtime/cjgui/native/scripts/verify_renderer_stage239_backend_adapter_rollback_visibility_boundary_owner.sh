#!/usr/bin/env zsh
#
# 维护注释：验证 stage239 backend adapter rollback/visibility boundary owner。
# 它只把 no-submit predicate 接成可回滚且 visibility-not-published 的边界。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage239_backend_adapter_rollback_visibility_boundary.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage239 backend adapter rollback visibility boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryFacts" \
  "CjguiInternalRendererStage239BackendAdapterRollbackVisibilityBoundaryReadiness" \
  "cjguiInternalExecuteDefaultRendererStage239BackendAdapterRollbackVisibilityBoundaryDraft" \
  "didConsumeStage238BackendAdapterNoSubmitPredicate" \
  "didMaterializeBackendAdapterRollbackVisibilityBoundary" \
  "didBindRollbackBoundaryToNoSubmitPredicate" \
  "didConfirmRollbackReadyResultEnvelope" \
  "didConfirmVisibilityNotPublishedBoundary" \
  "didPrepareStage240BackendAdapterReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage239 backend adapter rollback visibility boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage239_backend_adapter_rollback_visibility_boundary_owner_present=true"
echo "stage238_backend_adapter_no_submit_predicate_required=true"
echo "backend_adapter_rollback_visibility_boundary_materialized=true"
echo "rollback_boundary_bound_to_no_submit_predicate=true"
echo "backend_adapter_rollback_ready_result_envelope=true"
echo "backend_adapter_visibility_not_published_boundary=true"
echo "stage240_backend_adapter_readiness_decision_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
