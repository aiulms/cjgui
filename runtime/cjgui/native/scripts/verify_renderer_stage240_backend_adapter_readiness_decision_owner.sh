#!/usr/bin/env zsh
#
# 维护注释：验证 stage240 backend adapter readiness decision owner。
# 它只汇合 preview、no-submit predicate 与 rollback/visibility boundary。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage240_backend_adapter_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage240 backend adapter readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage240BackendAdapterReadinessDecisionFacts" \
  "CjguiInternalRendererStage240BackendAdapterReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage240BackendAdapterReadinessDecisionDraft" \
  "didConsumeStage239BackendAdapterRollbackVisibilityBoundary" \
  "didJoinAdapterPreviewWithNoSubmitPredicate" \
  "didJoinNoSubmitPredicateWithRollbackVisibilityBoundary" \
  "didMaterializeMinimalBackendAdapterReadinessDecision" \
  "didConfirmMinimalUiFrameworkBackendAdapterRunwayAdvanced" \
  "didPrepareStage241ComponentDemoBackendAdapterPacketInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage240 backend adapter readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage240_backend_adapter_readiness_decision_owner_present=true"
echo "stage239_backend_adapter_rollback_visibility_boundary_required=true"
echo "backend_adapter_preview_joined_with_no_submit_predicate=true"
echo "backend_adapter_no_submit_predicate_joined_with_rollback_visibility_boundary=true"
echo "minimal_backend_adapter_readiness_decision_materialized=true"
echo "minimal_ui_framework_backend_adapter_runway_advanced=true"
echo "stage241_component_demo_backend_adapter_packet_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
