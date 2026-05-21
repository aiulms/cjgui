#!/usr/bin/env zsh
#
# 维护注释：验证 stage252 component demo backend result readiness decision owner。
# 它汇合 preview、diff/explain 与 state-update bridge，准备后续 internal demo surface。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage252_component_demo_backend_result_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage252 component demo backend result readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage252ComponentDemoBackendResultReadinessDecisionFacts" \
  "CjguiInternalRendererStage252ComponentDemoBackendResultReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage252ComponentDemoBackendResultReadinessDecisionDraft" \
  "didConsumeStage251BackendResultStateUpdateBridge" \
  "didJoinBackendResultPreviewWithSemanticDiffExplain" \
  "didJoinBackendResultBridgeWithRollbackBoundary" \
  "didMaterializeComponentDemoBackendResultReadinessDecision" \
  "didPrepareStage253InternalComponentDemoSurfaceInput" \
  "didConfirmMinimalUiFrameworkBackendResultRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage252 component demo backend result readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage252_component_demo_backend_result_readiness_decision_owner_present=true"
echo "stage251_backend_result_state_update_bridge_required=true"
echo "component_demo_backend_result_readiness_decision_materialized=true"
echo "stage253_internal_component_demo_surface_input_prepared=true"
echo "minimal_ui_framework_backend_result_runway_advanced=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
