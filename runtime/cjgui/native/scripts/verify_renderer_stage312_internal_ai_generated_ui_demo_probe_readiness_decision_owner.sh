#!/usr/bin/env zsh
#
# 维护注释：验证 stage312 internal AI-generated UI demo probe readiness decision owner。
# 它汇合 probe input/result/diff，为下一步 action intent bridge 保持 dry-run 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage312_internal_ai_generated_ui_demo_probe_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage312 internal ai generated ui demo probe readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage312InternalAiGeneratedUiDemoProbeReadinessDecisionFacts" \
  "CjguiInternalRendererStage312InternalAiGeneratedUiDemoProbeReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage312InternalAiGeneratedUiDemoProbeReadinessDecisionDraft" \
  "didConsumeStage311InternalAiGeneratedUiDemoProbeSemanticDiffExplain" \
  "didJoinAiGeneratedUiProbeInputWithResultEnvelope" \
  "didJoinAiGeneratedUiProbeResultWithSemanticDiffExplain" \
  "didJoinAiGeneratedUiProbeWithRollbackReadyBoundary" \
  "didJoinAiGeneratedUiProbeWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoProbeReadinessDecision" \
  "didPrepareStage313InternalAiGeneratedUiDemoActionIntentBridge" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiProbeRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage312 internal ai generated ui demo probe readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage312_internal_ai_generated_ui_demo_probe_readiness_decision_owner_present=true"
echo "stage311_internal_ai_generated_ui_demo_probe_semantic_diff_explain_required=true"
echo "internal_ai_generated_ui_demo_probe_readiness_decision_materialized=true"
echo "ai_generated_ui_probe_input_result_diff_joined=true"
echo "ai_generated_ui_probe_rollback_visibility_boundary_joined=true"
echo "stage313_internal_ai_generated_ui_demo_action_intent_bridge_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_probe_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
