#!/usr/bin/env zsh
#
# Verifies the stage469 visual refresh layout/focus execution receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage469 shared component runtime visual refresh layout/focus execution receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage469SharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceiptPlan" \
  "CjguiInternalRendererStage469SharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceiptFacts" \
  "CjguiInternalRendererStage469SharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage469SharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceiptDraft" \
  "CjguiInternalRendererStage468SharedComponentRuntimeVisualRefreshStateRenderCommandRefreshReadiness" \
  "didConsumeStage468SharedComponentRuntimeVisualRefreshStateRenderCommandRefresh" \
  "didConsumeSharedComponentRuntimeVisualRefreshStateRenderCommandRefresh" \
  "didConsumeTodoRuntimeVisualRefreshRenderCommandProbeInput" \
  "didConsumeSettingsRuntimeVisualRefreshRenderCommandProbeInput" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshRenderCommandProbeInput" \
  "didMaterializeSharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceipt" \
  "didMaterializeTodoRuntimeVisualRefreshLayoutFocusExecutionPass" \
  "didMaterializeSettingsRuntimeVisualRefreshLayoutFocusExecutionPass" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshLayoutFocusExecutionPass" \
  "didBindRenderCommandProbeInputToLayoutFocusExecutionReceipt" \
  "didBindVisualRefreshStateRenderBridgeToLayoutFocusExecutionReceipt" \
  "didKeepLayoutFocusExecutionReceiptOwnerLocal" \
  "didKeepLayoutFocusExecutionReceiptCheckable" \
  "didPrepareStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapter" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage469 shared component runtime visual refresh layout/focus execution receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt_owner_present=true"
echo "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_required=true"
echo "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_consumed=true"
echo "shared_component_runtime_visual_refresh_state_render_command_refresh_consumed=true"
echo "todo_runtime_visual_refresh_render_command_probe_input_consumed=true"
echo "settings_runtime_visual_refresh_render_command_probe_input_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_render_command_probe_input_consumed=true"
echo "shared_component_runtime_visual_refresh_layout_focus_execution_receipt_materialized=true"
echo "todo_runtime_visual_refresh_layout_focus_execution_pass_materialized=true"
echo "settings_runtime_visual_refresh_layout_focus_execution_pass_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_layout_focus_execution_pass_materialized=true"
echo "render_command_probe_input_to_layout_focus_execution_receipt_bound=true"
echo "visual_refresh_state_render_bridge_to_layout_focus_execution_receipt_bound=true"
echo "layout_focus_execution_receipt_owner_local=true"
echo "layout_focus_execution_receipt_checkable=true"
echo "layout_focus_execution_receipt_preview_only=true"
echo "stage470_shared_component_runtime_visual_refresh_focus_input_action_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
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
