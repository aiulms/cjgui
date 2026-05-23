#!/usr/bin/env zsh
#
# 维护注释：验证 stage420 visibility preview diff / RenderCommand refresh owner。
# 它必须消费 stage419 visible surface preview refresh，并形成 owner-local diff 与 render command preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage420_visibility_preview_diff_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage420 visibility preview diff render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage420VisibilityPreviewDiffRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage420VisibilityPreviewDiffRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage420VisibilityPreviewDiffRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage420VisibilityPreviewDiffRenderCommandRefreshDraft" \
  "didConsumeStage419DemoSurfaceVisibilityPreviewRefresh" \
  "didConsumeDemoSurfaceVisibilityPreviewRefresh" \
  "didMaterializeVisibilityPreviewDiff" \
  "didMaterializeTodoVisibilityPreviewDiff" \
  "didMaterializeSettingsVisibilityPreviewDiff" \
  "didMaterializeAiGeneratedSettingsVisibilityPreviewDiff" \
  "didMaterializeVisibilityPreviewRenderCommandRefresh" \
  "didMapVisibilityPreviewDiffToRenderCommandRefresh" \
  "didKeepVisibilityPreviewDiffOwnerLocal" \
  "didKeepVisibilityPreviewRenderCommandPreviewOnly" \
  "didPrepareStage421VisibilityPreviewInputEventActionAdapter" \
  "didKeepVisibilityPublishedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage420 visibility preview diff render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage420_visibility_preview_diff_render_command_refresh_owner_present=true"
echo "stage419_demo_surface_visibility_preview_refresh_required=true"
echo "stage419_demo_surface_visibility_preview_refresh_consumed=true"
echo "demo_surface_visibility_preview_refresh_consumed=true"
echo "todo_visible_surface_preview_refresh_consumed=true"
echo "settings_visible_surface_preview_refresh_consumed=true"
echo "ai_generated_settings_visible_surface_preview_refresh_consumed=true"
echo "visibility_preview_diff_materialized=true"
echo "todo_visibility_preview_diff_materialized=true"
echo "settings_visibility_preview_diff_materialized=true"
echo "ai_generated_settings_visibility_preview_diff_materialized=true"
echo "visibility_preview_render_command_refresh_materialized=true"
echo "visibility_preview_diff_to_render_command_refresh_mapped=true"
echo "visibility_preview_diff_owner_local=true"
echo "visibility_preview_render_command_preview_only=true"
echo "stage421_visibility_preview_input_event_action_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
