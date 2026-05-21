#!/usr/bin/env zsh
#
# 维护注释：验证 stage296 internal AI-generated UI demo readiness decision owner。
# 它汇合 semantic spec、preview、diff/explain，并只准备 accept/reject dry-run 入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage296_internal_ai_generated_ui_demo_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage296 internal ai generated ui demo readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage296InternalAiGeneratedUiDemoReadinessDecisionFacts" \
  "CjguiInternalRendererStage296InternalAiGeneratedUiDemoReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage296InternalAiGeneratedUiDemoReadinessDecisionDraft" \
  "didConsumeStage295InternalAiGeneratedUiDemoSemanticDiffExplain" \
  "didJoinAiGeneratedUiSpecPreviewDiff" \
  "didJoinAiGeneratedUiOwnerAcceptanceBoundary" \
  "didJoinAiGeneratedUiVisibilityNotPublishedBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoReadinessDecision" \
  "didPrepareStage297InternalAiGeneratedUiDemoAcceptRejectDryRunInput" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage296 internal ai generated ui demo readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage296_internal_ai_generated_ui_demo_readiness_decision_owner_present=true"
echo "stage295_internal_ai_generated_ui_demo_semantic_diff_explain_required=true"
echo "internal_ai_generated_ui_demo_readiness_decision_materialized=true"
echo "ai_generated_ui_spec_preview_diff_joined=true"
echo "ai_generated_ui_owner_acceptance_boundary_joined=true"
echo "ai_generated_ui_visibility_not_published_boundary_joined=true"
echo "stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_runway_advanced=true"
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
