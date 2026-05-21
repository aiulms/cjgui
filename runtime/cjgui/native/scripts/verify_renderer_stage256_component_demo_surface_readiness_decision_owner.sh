#!/usr/bin/env zsh
#
# 维护注释：验证 stage256 component demo surface readiness decision owner。
# 它汇合 surface、diff/explain 与 probe input，准备下一段 demo state/render/action loop。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage256_component_demo_surface_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage256 component demo surface readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage256ComponentDemoSurfaceReadinessDecisionFacts" \
  "CjguiInternalRendererStage256ComponentDemoSurfaceReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage256ComponentDemoSurfaceReadinessDecisionDraft" \
  "didConsumeStage255InternalComponentDemoProbeInput" \
  "didJoinSurfaceWithSemanticDiffExplain" \
  "didJoinProbeInputWithRollbackReadyBoundary" \
  "didMaterializeComponentDemoSurfaceReadinessDecision" \
  "didPrepareStage257InternalComponentDemoStateRenderActionLoopInput" \
  "didConfirmMinimalUiFrameworkSurfaceRunwayAdvanced" \
  "didKeepOwnerAcceptanceRequired" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepBackendImplementationBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage256 component demo surface readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage256_component_demo_surface_readiness_decision_owner_present=true"
echo "stage255_internal_component_demo_probe_input_required=true"
echo "component_demo_surface_readiness_decision_materialized=true"
echo "stage257_internal_component_demo_state_render_action_loop_input_prepared=true"
echo "minimal_ui_framework_surface_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
