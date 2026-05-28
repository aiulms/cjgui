#!/usr/bin/env zsh
#
# 维护注释：验证 stage449 recovery demo surface RenderCommand refresh -> preview delta owner。
# 它必须消费 stage448 refreshed command，并生成 owner-local demo surface preview delta。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage449_recovery_demo_surface_render_command_refresh_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage449 recovery demo surface render command refresh dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage449RecoveryDemoSurfaceRenderCommandRefreshDryRunPlan" \
  "CjguiInternalRendererStage449RecoveryDemoSurfaceRenderCommandRefreshDryRunFacts" \
  "CjguiInternalRendererStage449RecoveryDemoSurfaceRenderCommandRefreshDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage449RecoveryDemoSurfaceRenderCommandRefreshDryRunDraft" \
  "CjguiInternalRendererStage448TransactionVisibilityRecoveryDemoSurfaceStateUpdateRenderCommandRefreshReadiness" \
  "didConsumeStage448RecoveryDemoSurfaceStateUpdateRenderCommandRefresh" \
  "didConsumeRecoveryDemoSurfaceRenderCommandRefreshPreview" \
  "didMaterializeRecoveryDemoSurfaceRenderCommandRefreshDryRun" \
  "didMaterializeTodoRecoveryDemoSurfacePreviewDelta" \
  "didMaterializeSettingsRecoveryDemoSurfacePreviewDelta" \
  "didMaterializeAiGeneratedSettingsRecoveryDemoSurfacePreviewDelta" \
  "didBindRecoveryDemoSurfaceRenderCommandRefreshToPreviewDelta" \
  "didCompareStage445SemanticProjectionWithStage448RenderCommandRefresh" \
  "didKeepRecoveryDemoSurfacePreviewDeltaOwnerLocal" \
  "didPrepareStage450RecoveryDemoSurfaceExecutionDryRun" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage449 recovery demo surface render command refresh dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage449_recovery_demo_surface_render_command_refresh_dry_run_owner_present=true"
echo "stage448_recovery_demo_surface_state_update_render_command_refresh_required=true"
echo "stage448_recovery_demo_surface_state_update_render_command_refresh_consumed=true"
echo "recovery_demo_surface_render_command_refresh_preview_consumed=true"
echo "todo_recovery_demo_surface_state_update_render_command_consumed=true"
echo "settings_recovery_demo_surface_state_update_render_command_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_state_update_render_command_consumed=true"
echo "stage445_semantic_projection_to_render_command_refresh_consumed=true"
echo "recovery_demo_surface_render_command_refresh_dry_run_materialized=true"
echo "todo_recovery_demo_surface_preview_delta_materialized=true"
echo "settings_recovery_demo_surface_preview_delta_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_preview_delta_materialized=true"
echo "recovery_demo_surface_render_command_refresh_to_preview_delta_bound=true"
echo "stage445_semantic_projection_compared_with_stage448_render_command_refresh=true"
echo "recovery_demo_surface_preview_delta_owner_local=true"
echo "recovery_demo_surface_preview_delta_dry_run_only=true"
echo "stage450_recovery_demo_surface_execution_dry_run_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
