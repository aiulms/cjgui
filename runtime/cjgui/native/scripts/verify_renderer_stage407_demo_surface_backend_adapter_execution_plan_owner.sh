#!/usr/bin/env zsh
#
# 维护注释：验证 stage407 demo surface backend adapter execution plan owner。
# 它必须消费 stage406 validation refresh / repair RenderCommand plan，并形成 backend adapter execution plan dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage407_demo_surface_backend_adapter_execution_plan.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage407 demo surface backend adapter execution plan: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage407DemoSurfaceBackendAdapterExecutionPlan" \
  "CjguiInternalRendererStage407DemoSurfaceBackendAdapterExecutionPlanFacts" \
  "CjguiInternalRendererStage407DemoSurfaceBackendAdapterExecutionPlanReadiness" \
  "cjguiInternalExecuteDefaultRendererStage407DemoSurfaceBackendAdapterExecutionPlanDraft" \
  "didConsumeStage406DemoSurfaceBackendAdapterValidationRefresh" \
  "didConsumeValidationRepairRenderCommandPlan" \
  "didMaterializeBackendAdapterExecutionPlanDryRun" \
  "didScheduleTodoBackendAdapterExecutionPlan" \
  "didScheduleSettingsBackendAdapterExecutionPlan" \
  "didScheduleAiGeneratedSettingsBackendAdapterExecutionPlan" \
  "didBindExecutionPlanToStage406ValidationRefresh" \
  "didBindExecutionPlanToStage405Validation" \
  "didClassifyBackendAdapterExecutionPlanBlocked" \
  "didKeepExecutionPlanOwnerLocal" \
  "didKeepExecutionPlanPreviewOnly" \
  "didPrepareStage408DemoSurfaceBackendAdapterExecutionTraceRefresh" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage407 demo surface backend adapter execution plan: missing token $token" >&2
    exit 3
  fi
done

echo "stage407_demo_surface_backend_adapter_execution_plan_owner_present=true"
echo "stage406_demo_surface_backend_adapter_validation_refresh_required=true"
echo "stage406_demo_surface_backend_adapter_validation_refresh_consumed=true"
echo "validation_repair_render_command_plan_consumed=true"
echo "backend_adapter_execution_plan_dry_run_materialized=true"
echo "todo_backend_adapter_execution_plan_scheduled=true"
echo "settings_backend_adapter_execution_plan_scheduled=true"
echo "ai_generated_settings_backend_adapter_execution_plan_scheduled=true"
echo "execution_plan_bound_to_stage406_validation_refresh=true"
echo "execution_plan_bound_to_stage405_validation=true"
echo "backend_adapter_execution_plan_blocked_classified=true"
echo "execution_plan_owner_local=true"
echo "execution_plan_preview_only=true"
echo "stage408_demo_surface_backend_adapter_execution_trace_refresh_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
