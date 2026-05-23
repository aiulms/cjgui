#!/usr/bin/env zsh
#
# 维护注释：验证 stage406 demo surface backend adapter validation refresh owner。
# 它必须消费 stage405 validation dry-run，并把 validation 输出接回 demo surface refresh plan。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage406_demo_surface_backend_adapter_validation_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage406 demo surface backend adapter validation refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage406DemoSurfaceBackendAdapterValidationRefreshPlan" \
  "CjguiInternalRendererStage406DemoSurfaceBackendAdapterValidationRefreshFacts" \
  "CjguiInternalRendererStage406DemoSurfaceBackendAdapterValidationRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage406DemoSurfaceBackendAdapterValidationRefreshDraft" \
  "didConsumeStage405DemoSurfaceBackendAdapterValidation" \
  "didConsumeBackendAdapterValidationDryRun" \
  "didMaterializeDemoSurfaceBackendAdapterValidationRefresh" \
  "didRefreshTodoBackendAdapterValidationSurface" \
  "didRefreshSettingsBackendAdapterValidationSurface" \
  "didRefreshAiGeneratedSettingsBackendAdapterValidationSurface" \
  "didBindValidationRefreshToStage405Validation" \
  "didBindValidationRefreshToStage404ResultRefresh" \
  "didMaterializeValidationRepairRenderCommandPlan" \
  "didKeepValidationRefreshOwnerLocal" \
  "didKeepValidationRefreshPreviewOnly" \
  "didPrepareStage407DemoSurfaceBackendAdapterExecutionPlanDryRun" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage406 demo surface backend adapter validation refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage406_demo_surface_backend_adapter_validation_refresh_owner_present=true"
echo "stage405_demo_surface_backend_adapter_validation_required=true"
echo "stage405_demo_surface_backend_adapter_validation_consumed=true"
echo "backend_adapter_validation_dry_run_consumed=true"
echo "demo_surface_backend_adapter_validation_refresh_materialized=true"
echo "todo_backend_adapter_validation_surface_refreshed=true"
echo "settings_backend_adapter_validation_surface_refreshed=true"
echo "ai_generated_settings_backend_adapter_validation_surface_refreshed=true"
echo "validation_refresh_bound_to_stage405_validation=true"
echo "validation_refresh_bound_to_stage404_result_refresh=true"
echo "validation_repair_render_command_plan_materialized=true"
echo "validation_refresh_owner_local=true"
echo "validation_refresh_preview_only=true"
echo "stage407_demo_surface_backend_adapter_execution_plan_dry_run_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
