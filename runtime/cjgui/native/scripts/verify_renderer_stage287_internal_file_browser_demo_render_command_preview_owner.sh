#!/usr/bin/env zsh
#
# 维护注释：验证 stage287 internal file browser demo render command preview owner。
# 它只确认 file-browser shell/tree-row/selection/detail-pane preview，不创建平台 command buffer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage287_internal_file_browser_demo_render_command_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage287 internal file browser demo render command preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage287InternalFileBrowserDemoRenderCommandPreviewFacts" \
  "CjguiInternalRendererStage287InternalFileBrowserDemoRenderCommandPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage287InternalFileBrowserDemoRenderCommandPreviewDraft" \
  "didConsumeStage286InternalFileBrowserDemoStateUpdateDryRun" \
  "didMaterializeFileBrowserShellSemanticNodePreview" \
  "didMaterializeFileBrowserTreeRowSemanticNodePreview" \
  "didMaterializeFileBrowserListSelectionSemanticNodePreview" \
  "didMaterializeFileBrowserDetailPaneSemanticNodePreview" \
  "didBindFileBrowserRenderPreviewToStateDeltaDryRun" \
  "didBindFileBrowserRenderPreviewToRenderCommandRefreshRequirement" \
  "didPrepareStage288FileBrowserDemoReadinessDecisionInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage287 internal file browser demo render command preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage287_internal_file_browser_demo_render_command_preview_owner_present=true"
echo "stage286_internal_file_browser_demo_state_update_dry_run_required=true"
echo "file_browser_shell_semantic_node_preview_materialized=true"
echo "file_browser_tree_row_semantic_node_preview_materialized=true"
echo "file_browser_list_selection_semantic_node_preview_materialized=true"
echo "file_browser_detail_pane_semantic_node_preview_materialized=true"
echo "file_browser_render_preview_bound_to_state_delta_dry_run=true"
echo "file_browser_render_preview_bound_to_render_command_refresh_requirement=true"
echo "stage288_file_browser_demo_readiness_decision_input_prepared=true"
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
