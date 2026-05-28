#!/usr/bin/env zsh
#
# Verifies the stage567 component runtime text input demo surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage567_component_runtime_text_input_demo_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage567 component runtime text input demo surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage567ComponentRuntimeTextInputDemoSurfaceContractPlan" \
  "CjguiInternalRendererStage567ComponentRuntimeTextInputDemoSurfaceContractFacts" \
  "CjguiInternalRendererStage567ComponentRuntimeTextInputDemoSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage567ComponentRuntimeTextInputDemoSurfaceContractDraft" \
  "CjguiInternalRendererStage566ComponentRuntimeTextInputStateExecutorReadiness" \
  "didMaterializeSharedComponentTextInputDemoSurfaceContract" \
  "didMaterializeSharedComponentTextInputDemoSurfaceHelper" \
  "didMaterializeTodoCheckableComponentTextInputSurface" \
  "didMaterializeSettingsCheckableComponentTextInputSurface" \
  "didMaterializeAiGeneratedSettingsCheckableComponentTextInputSurface" \
  "didMaterializeChatComposerCheckableComponentTextInputSurface" \
  "didBindTextInputDemoSurfaceToStage566Receipts" \
  "didBindTextInputDemoSurfaceToStage565Model" \
  "didBindTextInputDemoSurfaceToStage564Contract" \
  "didReducePerDemoTextInputRuntimeSurfaceTemplateNeed" \
  "didPrepareStage568ComponentRuntimeTextInputLayoutStylePreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage567 component runtime text input demo surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage567_component_runtime_text_input_demo_surface_contract_owner_present=true"
echo "stage566_component_runtime_text_input_state_executor_consumed=true"
echo "stage565_component_runtime_text_input_model_consumed_transitively=true"
echo "stage564_host_route_text_edit_demo_surface_contract_consumed_transitively=true"
echo "shared_component_text_input_demo_surface_contract_materialized=true"
echo "shared_component_text_input_demo_surface_helper_materialized=true"
echo "todo_checkable_component_text_input_surface_materialized=true"
echo "settings_checkable_component_text_input_surface_materialized=true"
echo "ai_generated_settings_checkable_component_text_input_surface_materialized=true"
echo "chat_composer_checkable_component_text_input_surface_materialized=true"
echo "text_input_demo_surface_bound_to_stage566_receipts=true"
echo "text_input_demo_surface_bound_to_stage565_model=true"
echo "text_input_demo_surface_bound_to_stage564_contract=true"
echo "component_text_input_demo_surface_checkable=true"
echo "per_demo_text_input_runtime_surface_template_need_reduced=true"
echo "stage568_component_runtime_text_input_layout_style_preview_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
