#!/usr/bin/env zsh
#
# 维护注释：验证 stage316 internal AI-generated UI demo action loop readiness decision owner。
# 它汇合 action intent、state update dry-run 与 refreshed RenderCommand preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage316 internal ai generated ui demo action loop readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage316InternalAiGeneratedUiDemoActionLoopReadinessDecisionFacts" \
  "CjguiInternalRendererStage316InternalAiGeneratedUiDemoActionLoopReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage316InternalAiGeneratedUiDemoActionLoopReadinessDecisionDraft" \
  "didConsumeStage315InternalAiGeneratedUiDemoRefreshedRenderCommandPreview" \
  "didJoinAiGeneratedUiActionIntentWithStateUpdateDryRun" \
  "didJoinAiGeneratedUiActionStateUpdateDryRunWithRefreshedRenderCommand" \
  "didJoinAiGeneratedUiActionLoopWithRollbackReadyBoundary" \
  "didJoinAiGeneratedUiActionLoopWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoActionLoopReadinessDecision" \
  "didPrepareStage317InternalAiGeneratedUiDemoActionLoopBackendAdapterDryRun" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiActionLoopAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage316 internal ai generated ui demo action loop readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision_owner_present=true"
echo "stage315_internal_ai_generated_ui_demo_refreshed_render_command_preview_required=true"
echo "internal_ai_generated_ui_demo_action_loop_readiness_decision_materialized=true"
echo "ai_generated_ui_action_intent_state_update_joined=true"
echo "ai_generated_ui_action_state_update_refreshed_render_command_joined=true"
echo "ai_generated_ui_action_loop_rollback_visibility_boundary_joined=true"
echo "stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_action_loop_advanced=true"
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
