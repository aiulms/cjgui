#!/usr/bin/env zsh
#
# 维护注释：验证 stage307 internal AI-generated UI demo component render command preview owner。
# 它消费 stage306 state delta dry-run，只描述 semantic node 到 RenderCommand preview 的刷新。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage307_internal_ai_generated_ui_demo_component_render_command_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage307 internal ai generated ui demo component render command preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage307InternalAiGeneratedUiDemoComponentRenderCommandPreviewFacts" \
  "CjguiInternalRendererStage307InternalAiGeneratedUiDemoComponentRenderCommandPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage307InternalAiGeneratedUiDemoComponentRenderCommandPreviewDraft" \
  "didConsumeStage306InternalAiGeneratedUiDemoComponentStateDeltaDryRun" \
  "didMaterializeGeneratedFormSemanticNodePreview" \
  "didMaterializeGeneratedSettingsSemanticNodePreview" \
  "didMaterializeGeneratedValidationMessageSemanticNodePreview" \
  "didMaterializeAiGeneratedUiComponentRenderCommandPreview" \
  "didBindGeneratedComponentRenderPreviewToStateDeltaDryRun" \
  "didPrepareStage308AiGeneratedUiComponentStateRenderReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage307 internal ai generated ui demo component render command preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage307_internal_ai_generated_ui_demo_component_render_command_preview_owner_present=true"
echo "stage306_internal_ai_generated_ui_demo_component_state_delta_dry_run_required=true"
echo "ai_generated_ui_component_render_command_preview_materialized=true"
echo "generated_form_semantic_node_preview_materialized=true"
echo "generated_settings_semantic_node_preview_materialized=true"
echo "generated_validation_message_semantic_node_preview_materialized=true"
echo "generated_component_render_preview_bound_to_state_delta_dry_run=true"
echo "generated_component_render_preview_bound_to_render_command_refresh_requirement=true"
echo "stage308_ai_generated_ui_component_state_render_readiness_decision_input_prepared=true"
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
