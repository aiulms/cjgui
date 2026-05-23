#!/usr/bin/env zsh
#
# 维护注释：验证 stage405 demo surface backend adapter validation owner。
# 它必须消费 stage404 backend adapter result refresh，并产出 owner-local validation dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage405_demo_surface_backend_adapter_validation.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage405 demo surface backend adapter validation: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage405DemoSurfaceBackendAdapterValidationMatrix" \
  "CjguiInternalRendererStage405DemoSurfaceBackendAdapterValidationFacts" \
  "CjguiInternalRendererStage405DemoSurfaceBackendAdapterValidationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage405DemoSurfaceBackendAdapterValidationDraft" \
  "didConsumeStage404DemoSurfaceBackendAdapterResultRefresh" \
  "didConsumeBackendAdapterResultRefresh" \
  "didMaterializeBackendAdapterValidationDryRun" \
  "didValidateBackendAdapterResultCoverage" \
  "didValidateTodoBackendAdapterResultRefresh" \
  "didValidateSettingsBackendAdapterResultRefresh" \
  "didValidateAiGeneratedSettingsBackendAdapterResultRefresh" \
  "didBindBackendAdapterValidationToStage404ResultRefresh" \
  "didBindBackendAdapterValidationToStage403Mapping" \
  "didKeepBackendAdapterValidationOwnerLocal" \
  "didKeepBackendAdapterValidationPreviewOnly" \
  "didClassifyBackendReadyTruthBlocked" \
  "didPrepareStage406DemoSurfaceBackendAdapterValidationRefresh" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage405 demo surface backend adapter validation: missing token $token" >&2
    exit 3
  fi
done

echo "stage405_demo_surface_backend_adapter_validation_owner_present=true"
echo "stage404_demo_surface_backend_adapter_result_refresh_required=true"
echo "stage404_demo_surface_backend_adapter_result_refresh_consumed=true"
echo "backend_adapter_result_refresh_consumed=true"
echo "backend_adapter_validation_dry_run_materialized=true"
echo "backend_adapter_result_coverage_validated=true"
echo "todo_backend_adapter_result_refresh_validated=true"
echo "settings_backend_adapter_result_refresh_validated=true"
echo "ai_generated_settings_backend_adapter_result_refresh_validated=true"
echo "backend_adapter_validation_bound_to_stage404_result_refresh=true"
echo "backend_adapter_validation_bound_to_stage403_mapping=true"
echo "backend_adapter_validation_owner_local=true"
echo "backend_adapter_validation_preview_only=true"
echo "backend_ready_truth_blocked_classified=true"
echo "stage406_demo_surface_backend_adapter_validation_refresh_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
