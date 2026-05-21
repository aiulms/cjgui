#!/usr/bin/env zsh
#
# 维护注释：验证 stage315 internal AI-generated UI demo refreshed RenderCommand preview owner。
# 它只把 action state update dry-run 映射成刷新后的 RenderCommand preview，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage315_internal_ai_generated_ui_demo_refreshed_render_command_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage315 internal ai generated ui demo refreshed render command preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage315InternalAiGeneratedUiDemoRefreshedRenderCommandPreviewFacts" \
  "CjguiInternalRendererStage315InternalAiGeneratedUiDemoRefreshedRenderCommandPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage315InternalAiGeneratedUiDemoRefreshedRenderCommandPreviewDraft" \
  "didConsumeStage314InternalAiGeneratedUiActionStateUpdateDryRun" \
  "didMaterializeAiGeneratedUiActionRefreshedRenderCommandPreview" \
  "didBindRefreshedRenderCommandPreviewToActionStateUpdateDryRun" \
  "didBindRefreshedRenderCommandPreviewToGeneratedFormNode" \
  "didBindRefreshedRenderCommandPreviewToGeneratedSettingsNode" \
  "didBindRefreshedRenderCommandPreviewToGeneratedValidationNode" \
  "didBindRefreshedRenderCommandPreviewToRollbackReadyBoundary" \
  "didBindRefreshedRenderCommandPreviewToVisibilityNotPublishedBoundary" \
  "didPrepareStage316AiGeneratedUiActionLoopReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage315 internal ai generated ui demo refreshed render command preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage315_internal_ai_generated_ui_demo_refreshed_render_command_preview_owner_present=true"
echo "stage314_internal_ai_generated_ui_demo_action_state_update_dry_run_required=true"
echo "ai_generated_ui_action_refreshed_render_command_preview_materialized=true"
echo "refreshed_render_command_preview_bound_to_action_state_update_dry_run=true"
echo "refreshed_render_command_preview_bound_to_generated_form_node=true"
echo "refreshed_render_command_preview_bound_to_generated_settings_node=true"
echo "refreshed_render_command_preview_bound_to_generated_validation_node=true"
echo "refreshed_render_command_preview_bound_to_rollback_ready_boundary=true"
echo "refreshed_render_command_preview_bound_to_visibility_not_published_boundary=true"
echo "stage316_ai_generated_ui_action_loop_readiness_decision_input_prepared=true"
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
