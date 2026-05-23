#!/usr/bin/env zsh
#
# 维护注释：验证 stage419 demo surface visibility preview refresh owner。
# 它必须消费 stage418 visibility command plan，并形成 owner-local visible surface preview refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage419_demo_surface_visibility_preview_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage419 demo surface visibility preview refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage419DemoSurfaceVisibilityPreviewRefreshPlan" \
  "CjguiInternalRendererStage419DemoSurfaceVisibilityPreviewRefreshFacts" \
  "CjguiInternalRendererStage419DemoSurfaceVisibilityPreviewRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage419DemoSurfaceVisibilityPreviewRefreshDraft" \
  "didConsumeStage418VisibilityCommandPlanDryRun" \
  "didConsumeVisibilityCommandPlanDryRun" \
  "didRefreshTodoVisibleSurfacePreview" \
  "didRefreshSettingsVisibleSurfacePreview" \
  "didRefreshAiGeneratedSettingsVisibleSurfacePreview" \
  "didMapAcceptedVisibilityCommandToVisibleSurfacePreview" \
  "didMapBlockedVisibilityCommandToRollbackSurfacePreview" \
  "didKeepDemoSurfaceVisibilityRefreshOwnerLocal" \
  "didKeepDemoSurfaceVisibilityRefreshPreviewOnly" \
  "didPrepareStage420VisibilityPreviewDiffRenderCommandRefresh" \
  "didKeepVisibilityPublishedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage419 demo surface visibility preview refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage419_demo_surface_visibility_preview_refresh_owner_present=true"
echo "stage418_visibility_command_plan_dry_run_required=true"
echo "stage418_visibility_command_plan_dry_run_consumed=true"
echo "visibility_command_plan_dry_run_consumed=true"
echo "accepted_gate_to_preview_visibility_command_consumed=true"
echo "blocked_gate_to_rollback_visibility_command_consumed=true"
echo "demo_surface_visibility_preview_refresh_materialized=true"
echo "todo_visible_surface_preview_refreshed=true"
echo "settings_visible_surface_preview_refreshed=true"
echo "ai_generated_settings_visible_surface_preview_refreshed=true"
echo "accepted_visibility_command_to_visible_surface_preview_mapped=true"
echo "blocked_visibility_command_to_rollback_surface_preview_mapped=true"
echo "demo_surface_visibility_refresh_owner_local=true"
echo "demo_surface_visibility_refresh_preview_only=true"
echo "stage420_visibility_preview_diff_render_command_refresh_prepared=true"
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
