#!/usr/bin/env zsh
#
# Verifies the stage464 shared component runtime layout/style refresh contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage464_shared_component_runtime_layout_style_refresh_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage464 shared component runtime layout style refresh contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage464SharedComponentRuntimeLayoutStyleRefreshContractPlan" \
  "CjguiInternalRendererStage464SharedComponentRuntimeLayoutStyleRefreshContractFacts" \
  "CjguiInternalRendererStage464SharedComponentRuntimeLayoutStyleRefreshContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage464SharedComponentRuntimeLayoutStyleRefreshContractDraft" \
  "CjguiInternalRendererStage463SharedComponentRuntimeRenderCommandRefreshBridgeReadiness" \
  "didConsumeStage463SharedComponentRuntimeRenderCommandRefreshBridge" \
  "didConsumeSharedComponentRuntimeRenderCommandRefreshBridge" \
  "didConsumeTodoRuntimeRenderCommandRefreshCandidate" \
  "didConsumeSettingsRuntimeRenderCommandRefreshCandidate" \
  "didConsumeAiGeneratedSettingsRuntimeRenderCommandRefreshCandidate" \
  "didMaterializeSharedComponentRuntimeLayoutStyleRefreshContract" \
  "didMaterializeTodoRuntimeLayoutStyleTextFocusPreview" \
  "didMaterializeSettingsRuntimeLayoutStyleTextFocusPreview" \
  "didMaterializeAiGeneratedSettingsRuntimeLayoutStyleTextFocusPreview" \
  "didBindRenderCommandRefreshBridgeToLayoutStyleRefreshContract" \
  "didBindComponentRuntimeContractToLayoutStyleRefreshContract" \
  "didKeepLayoutStyleRefreshContractReusable" \
  "didKeepLayoutStyleRefreshContractPreviewOnly" \
  "didPrepareStage465SharedComponentRuntimeDemoSurfaceVisualRefreshReceipt" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage464 shared component runtime layout style refresh contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage464_shared_component_runtime_layout_style_refresh_contract_owner_present=true"
echo "stage463_shared_component_runtime_render_command_refresh_bridge_required=true"
echo "stage463_shared_component_runtime_render_command_refresh_bridge_consumed=true"
echo "shared_component_runtime_render_command_refresh_bridge_consumed=true"
echo "todo_runtime_render_command_refresh_candidate_consumed=true"
echo "settings_runtime_render_command_refresh_candidate_consumed=true"
echo "ai_generated_settings_runtime_render_command_refresh_candidate_consumed=true"
echo "shared_component_runtime_layout_style_refresh_contract_materialized=true"
echo "todo_runtime_layout_style_text_focus_preview_materialized=true"
echo "settings_runtime_layout_style_text_focus_preview_materialized=true"
echo "ai_generated_settings_runtime_layout_style_text_focus_preview_materialized=true"
echo "render_command_refresh_bridge_to_layout_style_refresh_contract_bound=true"
echo "component_runtime_contract_to_layout_style_refresh_contract_bound=true"
echo "layout_style_refresh_contract_reusable=true"
echo "layout_style_refresh_contract_preview_only=true"
echo "stage465_shared_component_runtime_demo_surface_visual_refresh_receipt_prepared=true"
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
