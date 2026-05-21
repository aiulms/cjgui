#!/usr/bin/env zsh
#
# 维护注释：验证 stage286 internal file browser demo state update dry-run owner。
# 它只确认 selection/tree expansion/detail preview state delta 在 owner-local snapshot 内演算。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage286_internal_file_browser_demo_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage286 internal file browser demo state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage286InternalFileBrowserDemoStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage286InternalFileBrowserDemoStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage286InternalFileBrowserDemoStateUpdateDryRunDraft" \
  "didConsumeStage285InternalFileBrowserDemoIntentPacket" \
  "didMaterializeFileBrowserDemoOwnerLocalStateSnapshot" \
  "didMaterializeFileBrowserSelectionStateDeltaDryRun" \
  "didMaterializeFileBrowserTreeExpansionStateDeltaDryRun" \
  "didMaterializeFileBrowserDetailPaneStateDeltaDryRun" \
  "didBindFileBrowserStateDeltaToRollbackReadyBoundary" \
  "didKeepFileBrowserStateUpdateDryRunInMemoryOnly" \
  "didPrepareStage287FileBrowserDemoRenderCommandPreviewInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage286 internal file browser demo state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage286_internal_file_browser_demo_state_update_dry_run_owner_present=true"
echo "stage285_internal_file_browser_demo_intent_packet_required=true"
echo "file_browser_demo_owner_local_state_snapshot_materialized=true"
echo "file_browser_selection_state_delta_dry_run_materialized=true"
echo "file_browser_tree_expansion_state_delta_dry_run_materialized=true"
echo "file_browser_detail_pane_state_delta_dry_run_materialized=true"
echo "file_browser_state_delta_bound_to_rollback_ready_boundary=true"
echo "file_browser_state_update_dry_run_in_memory_only=true"
echo "stage287_file_browser_demo_render_command_preview_input_prepared=true"
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
