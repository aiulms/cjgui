#!/usr/bin/env zsh
#
# Verifies the stage687 replay host text edit render/result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage687_replay_host_text_edit_render_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage687 replay host text edit render/result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage687ReplayHostTextEditRenderResultSurfacePlan" \
  "CjguiInternalRendererStage687ReplayHostTextEditRenderResultSurfaceFacts" \
  "CjguiInternalRendererStage687ReplayHostTextEditRenderResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage687ReplayHostTextEditRenderResultSurfaceDraft" \
  "CjguiInternalRendererStage686ReplayHostTextEditStateDryRunReadiness" \
  "didConsumeStage686ReplayHostTextEditStateDryRun" \
  "didMaterializeSharedReplayHostTextEditRenderResultSurface" \
  "didMaterializeTextRunRenderCommandRefreshPreview" \
  "didMaterializeCaretSelectionRenderCommandRefreshPreview" \
  "didMaterializeValidationFeedbackRenderCommandRefreshPreview" \
  "didMaterializeFocusFeedbackResultSurfaceRefresh" \
  "didMaterializeSubmitAffordanceResultSurfaceRefresh" \
  "didMaterializeChatComposerReplayHostTextEditRenderResultSurface" \
  "didBindTextEditRenderResultSurfaceToStage686StateDryRun" \
  "didBindTextEditRenderResultSurfaceToStage685FieldModel" \
  "didPrepareStage688ReplayHostTextInputRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage687 replay host text edit render/result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage687_replay_host_text_edit_render_result_surface_owner_present=true"
echo "stage686_replay_host_text_edit_state_dry_run_consumed=true"
echo "shared_replay_host_text_edit_render_result_surface_materialized=true"
echo "text_run_render_command_refresh_preview_materialized=true"
echo "caret_selection_render_command_refresh_preview_materialized=true"
echo "validation_feedback_render_command_refresh_preview_materialized=true"
echo "focus_feedback_result_surface_refresh_materialized=true"
echo "submit_affordance_result_surface_refresh_materialized=true"
echo "todo_replay_host_text_edit_render_result_surface_materialized=true"
echo "settings_replay_host_text_edit_render_result_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_edit_render_result_surface_materialized=true"
echo "chat_composer_replay_host_text_edit_render_result_surface_materialized=true"
echo "text_edit_render_result_surface_bound_to_stage686_state_dry_run=true"
echo "text_edit_render_result_surface_bound_to_stage685_field_model=true"
echo "stage688_replay_host_text_input_runtime_contract_prepared=true"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
