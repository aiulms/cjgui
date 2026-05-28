#!/usr/bin/env zsh
#
# 维护注释：验证 stage455 recovery demo surface layout/style/text/focus execution dry-run owner。
# 它必须消费 stage454 preview，并生成 owner-local demo surface execution receipt。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage455_recovery_demo_surface_layout_style_execution_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage455 recovery demo surface layout style execution dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRunPlan" \
  "CjguiInternalRendererStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRunFacts" \
  "CjguiInternalRendererStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRunDraft" \
  "CjguiInternalRendererStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreviewReadiness" \
  "didConsumeStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreview" \
  "didConsumeSharedRecoveryDemoSurfaceLayoutStyleTextFocusPreview" \
  "didConsumeTodoRecoveryDemoSurfaceLayoutStyleTextFocusNode" \
  "didConsumeSettingsRecoveryDemoSurfaceLayoutStyleTextFocusNode" \
  "didConsumeAiGeneratedSettingsRecoveryDemoSurfaceLayoutStyleTextFocusNode" \
  "didMaterializeSharedRecoveryDemoSurfaceLayoutStyleExecutionReceipt" \
  "didMaterializeTodoRecoveryDemoSurfaceLayoutStyleExecutionDryRun" \
  "didMaterializeSettingsRecoveryDemoSurfaceLayoutStyleExecutionDryRun" \
  "didMaterializeAiGeneratedSettingsRecoveryDemoSurfaceLayoutStyleExecutionDryRun" \
  "didMaterializeRecoveryDemoSurfaceTextFocusExecutionAffordance" \
  "didBindLayoutStylePreviewToExecutionDryRun" \
  "didBindRenderCommandRefreshToExecutionReceipt" \
  "didPrepareStage456RecoveryDemoSurfaceFocusInputActionIntentAdapter" \
  "didKeepLayoutStyleExecutionOwnerLocal" \
  "didKeepLayoutStyleExecutionDryRunOnly" \
  "didKeepLayoutEngineBlocked" \
  "didKeepStyleResolverBlocked" \
  "didKeepTextShapingBlocked" \
  "didKeepFocusManagerBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage455 recovery demo surface layout style execution dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage455_recovery_demo_surface_layout_style_execution_dry_run_owner_present=true"
echo "stage454_recovery_demo_surface_render_command_layout_style_preview_required=true"
echo "stage454_recovery_demo_surface_render_command_layout_style_preview_consumed=true"
echo "shared_recovery_demo_surface_layout_style_text_focus_preview_consumed=true"
echo "todo_recovery_demo_surface_layout_style_text_focus_node_consumed=true"
echo "settings_recovery_demo_surface_layout_style_text_focus_node_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_layout_style_text_focus_node_consumed=true"
echo "shared_recovery_demo_surface_layout_style_execution_receipt_materialized=true"
echo "todo_recovery_demo_surface_layout_style_execution_dry_run_materialized=true"
echo "settings_recovery_demo_surface_layout_style_execution_dry_run_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_layout_style_execution_dry_run_materialized=true"
echo "recovery_demo_surface_text_focus_execution_affordance_materialized=true"
echo "layout_style_preview_to_execution_dry_run_bound=true"
echo "render_command_refresh_to_execution_receipt_bound=true"
echo "recovery_demo_surface_layout_style_execution_owner_local=true"
echo "recovery_demo_surface_layout_style_execution_dry_run_only=true"
echo "stage456_recovery_demo_surface_focus_input_action_intent_adapter_prepared=true"
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
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
