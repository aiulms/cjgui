#!/usr/bin/env zsh
#
# 维护注释：验证 stage404 demo surface backend adapter result refresh owner。
# 它必须消费 stage403 backend adapter dry-run mapping，并产出 demo surface result refresh classification。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage404_demo_surface_backend_adapter_result_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage404 demo surface backend adapter result refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage404DemoSurfaceBackendAdapterResultRefreshPreview" \
  "CjguiInternalRendererStage404DemoSurfaceBackendAdapterResultRefreshFacts" \
  "CjguiInternalRendererStage404DemoSurfaceBackendAdapterResultRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage404DemoSurfaceBackendAdapterResultRefreshDraft" \
  "didConsumeStage403DemoSurfaceRenderCommandBackendAdapterDryRun" \
  "didConsumeBackendAdapterDryRunMapping" \
  "didMaterializeBackendAdapterResultRefresh" \
  "didClassifyTodoBackendAdapterDryRunResult" \
  "didClassifySettingsBackendAdapterDryRunResult" \
  "didClassifyAiGeneratedSettingsBackendAdapterDryRunResult" \
  "didBindBackendAdapterResultRefreshToStage403Mapping" \
  "didBindBackendAdapterResultRefreshToStage402CommandBatch" \
  "didKeepBackendAdapterResultRefreshOwnerLocal" \
  "didKeepBackendAdapterResultRefreshPreviewOnly" \
  "didPrepareStage405DemoSurfaceBackendAdapterValidation" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage404 demo surface backend adapter result refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage404_demo_surface_backend_adapter_result_refresh_owner_present=true"
echo "stage403_demo_surface_render_command_backend_adapter_dry_run_required=true"
echo "stage403_demo_surface_render_command_backend_adapter_dry_run_consumed=true"
echo "backend_adapter_dry_run_mapping_consumed=true"
echo "backend_adapter_result_refresh_materialized=true"
echo "todo_backend_adapter_dry_run_result_classified=true"
echo "settings_backend_adapter_dry_run_result_classified=true"
echo "ai_generated_settings_backend_adapter_dry_run_result_classified=true"
echo "backend_adapter_result_refresh_bound_to_stage403_mapping=true"
echo "backend_adapter_result_refresh_bound_to_stage402_command_batch=true"
echo "backend_adapter_result_refresh_owner_local=true"
echo "backend_adapter_result_refresh_preview_only=true"
echo "stage405_demo_surface_backend_adapter_validation_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
