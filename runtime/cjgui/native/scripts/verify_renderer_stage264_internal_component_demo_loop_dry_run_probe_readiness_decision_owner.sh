#!/usr/bin/env zsh
#
# 维护注释：验证 stage264 internal component demo loop dry-run probe readiness decision owner。
# 它只把 demo loop dry-run probe 封成 readiness decision，并准备 Todo demo intent 下一入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage264_internal_component_demo_loop_dry_run_probe_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage264 internal component demo loop dry-run probe readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage264InternalComponentDemoLoopDryRunProbeReadinessDecisionFacts" \
  "CjguiInternalRendererStage264InternalComponentDemoLoopDryRunProbeReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage264InternalComponentDemoLoopDryRunProbeReadinessDecisionDraft" \
  "didConsumeStage263InternalComponentDemoLoopDryRunProbeSemanticDiffExplain" \
  "didJoinLoopDryRunProbeWithSemanticDiffExplain" \
  "didJoinLoopDryRunProbeWithRollbackReadyBoundary" \
  "didJoinLoopDryRunProbeWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalComponentDemoLoopDryRunProbeReadinessDecision" \
  "didPrepareStage265InternalTodoDemoIntentPacketInput" \
  "didConfirmMinimalUiFrameworkDemoLoopProbeRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage264 internal component demo loop dry-run probe readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_owner_present=true"
echo "stage263_internal_component_demo_loop_dry_run_probe_semantic_diff_explain_required=true"
echo "internal_component_demo_loop_dry_run_probe_readiness_decision_materialized=true"
echo "stage265_internal_todo_demo_intent_packet_input_prepared=true"
echo "minimal_ui_framework_demo_loop_probe_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
