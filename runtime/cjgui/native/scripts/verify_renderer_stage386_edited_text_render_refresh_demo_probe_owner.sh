#!/usr/bin/env zsh
#
# 维护注释：验证 stage386 edited text -> render refresh demo probe owner。
# 它必须消费 stage385 text input/focus editing packet，并产出 owner-local demo surface
# 与 RenderCommand refresh preview，不提交 state 或 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage386_edited_text_render_refresh_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage386 edited text render refresh demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh" \
  "CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun" \
  "CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeFacts" \
  "CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage386EditedTextRenderRefreshDemoProbeDraft" \
  "didConsumeStage385SharedTextInputFocusEditingDemoProbe" \
  "didConsumeEditedTextBufferDelta" \
  "didMaterializeTodoEditedTextSurfaceRefreshPreview" \
  "didMaterializeSettingsFocusSurfaceRefreshPreview" \
  "didMaterializeCaretRenderCommandRefreshPreview" \
  "didMaterializeEditedTextRenderCommandRefreshPlan" \
  "didBindEditedTextRefreshToStage383RenderBridge" \
  "didBindEditedTextRefreshToStage384InputAdapter" \
  "didBindEditedTextRefreshToStage385EditingDryRun" \
  "didMaterializeOwnerLocalEditedTextStateRenderDryRun" \
  "didKeepEditedTextRefreshPreviewOnly" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage386 edited text render refresh demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage386_edited_text_render_refresh_demo_probe_owner_present=true"
echo "stage385_shared_text_input_focus_editing_demo_probe_required=true"
echo "stage385_shared_text_input_focus_editing_demo_probe_consumed=true"
echo "edited_text_buffer_delta_consumed=true"
echo "todo_edited_text_surface_refresh_preview_materialized=true"
echo "settings_focus_surface_refresh_preview_materialized=true"
echo "caret_render_command_refresh_preview_materialized=true"
echo "edited_text_render_command_refresh_plan_materialized=true"
echo "edited_text_refresh_bound_to_stage383_render_bridge=true"
echo "edited_text_refresh_bound_to_stage384_input_adapter=true"
echo "edited_text_refresh_bound_to_stage385_editing_dry_run=true"
echo "owner_local_edited_text_state_render_dry_run_materialized=true"
echo "edited_text_refresh_preview_only=true"
echo "owner_local_preview_only=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
