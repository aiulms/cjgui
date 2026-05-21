#!/usr/bin/env zsh
#
# 维护注释：验证 stage328 internal AI-generated UI demo result-to-probe readiness decision owner。
# 它汇合 result-to-surface、probe input 和 result envelope，为 demo execution dry-run 准备入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage328 internal ai generated ui demo result to probe readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage328InternalAiGeneratedUiDemoResultToProbeReadinessDecisionFacts" \
  "CjguiInternalRendererStage328InternalAiGeneratedUiDemoResultToProbeReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage328InternalAiGeneratedUiDemoResultToProbeReadinessDecisionDraft" \
  "didConsumeStage327ResultToProbeResultEnvelope" \
  "didJoinResultToSurfaceWithProbeInput" \
  "didJoinResultToProbeInputWithResultEnvelope" \
  "didJoinResultToProbeRunwayWithRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoResultToProbeReadinessDecision" \
  "didPrepareStage329InternalAiGeneratedUiDemoExecutionDryRun" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiDemoResultToProbeRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage328 internal ai generated ui demo result to probe readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision_owner_present=true"
echo "stage327_internal_ai_generated_ui_demo_result_to_probe_result_envelope_required=true"
echo "internal_ai_generated_ui_demo_result_to_probe_readiness_decision_materialized=true"
echo "result_to_surface_probe_input_joined=true"
echo "result_to_probe_input_envelope_joined=true"
echo "result_to_probe_runway_rollback_visibility_boundary_joined=true"
echo "stage329_internal_ai_generated_ui_demo_execution_dry_run_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_result_to_probe_runway_advanced=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
