#!/usr/bin/env zsh
#
# 维护注释：验证 stage260 internal component demo loop readiness decision owner。
# 它只输出下一段 owner-local loop dry-run probe 输入，不升级 backend/runtime truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage260_internal_component_demo_loop_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage260 internal component demo loop readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage260InternalComponentDemoLoopReadinessDecisionFacts" \
  "CjguiInternalRendererStage260InternalComponentDemoLoopReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage260InternalComponentDemoLoopReadinessDecisionDraft" \
  "didConsumeStage259InternalComponentDemoLoopSemanticDiffExplain" \
  "didJoinLoopWithSemanticDiffExplain" \
  "didJoinLoopWithRollbackReadyBoundary" \
  "didMaterializeInternalComponentDemoLoopReadinessDecision" \
  "didPrepareStage261InternalComponentDemoLoopDryRunProbeInput" \
  "didConfirmMinimalUiFrameworkLoopRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage260 internal component demo loop readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage260_internal_component_demo_loop_readiness_decision_owner_present=true"
echo "stage259_internal_component_demo_loop_semantic_diff_explain_required=true"
echo "internal_component_demo_loop_readiness_decision_materialized=true"
echo "stage261_internal_component_demo_loop_dry_run_probe_input_prepared=true"
echo "minimal_ui_framework_loop_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
