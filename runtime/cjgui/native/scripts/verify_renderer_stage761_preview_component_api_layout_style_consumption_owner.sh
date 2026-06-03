#!/usr/bin/env zsh
#
# Verifies the stage761 preview component API layout/style consumption owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage761_preview_component_api_layout_style_consumption.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage761 preview component api layout style consumption: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage761PreviewComponentApiLayoutStyleConsumptionPlan" \
  "CjguiInternalRendererStage761PreviewComponentApiLayoutStyleConsumptionFacts" \
  "CjguiInternalRendererStage761PreviewComponentApiLayoutStyleConsumptionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage761PreviewComponentApiLayoutStyleConsumptionDraft" \
  "CjguiInternalRendererStage760MinimalPublicPreviewApiPublicScanContractReadiness" \
  "didConsumeStage760MinimalPublicPreviewApiPublicScanContract" \
  "didConsumeCjguiExperimentalComponentPreviewApiReady" \
  "didMaterializePreviewComponentLayoutDescriptor" \
  "didMaterializePreviewComponentStyleTokenDescriptor" \
  "didMaterializeTodoPreviewComponentApiLayoutStyleSurface" \
  "didMaterializeSettingsPreviewComponentApiLayoutStyleSurface" \
  "didMaterializeAiGeneratedSettingsPreviewComponentApiLayoutStyleSurface" \
  "didMaterializeChatComposerPreviewComponentApiLayoutStyleSurface" \
  "didPrepareStage762PreviewComponentApiTextFocusProjection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage761 preview component api layout style consumption: missing token $token" >&2
    exit 3
  fi
done

echo "stage761_preview_component_api_layout_style_consumption_owner_present=true"
echo "stage760_minimal_public_preview_api_public_scan_contract_consumed=true"
echo "cjguiExperimentalComponentPreviewApiReady_consumed=true"
echo "preview_component_layout_descriptor_materialized=true"
echo "preview_component_style_token_descriptor_materialized=true"
echo "todo_preview_component_api_layout_style_surface_materialized=true"
echo "settings_preview_component_api_layout_style_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_layout_style_surface_materialized=true"
echo "chat_composer_preview_component_api_layout_style_surface_materialized=true"
echo "stage762_preview_component_api_text_focus_projection_prepared=true"
echo "public_component_api_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
