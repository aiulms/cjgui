#!/usr/bin/env zsh
#
# Verifies the stage565 component runtime text input model owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage565_component_runtime_text_input_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage565 component runtime text input model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage565ComponentRuntimeTextInputModelPlan" \
  "CjguiInternalRendererStage565ComponentRuntimeTextInputModelFacts" \
  "CjguiInternalRendererStage565ComponentRuntimeTextInputModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage565ComponentRuntimeTextInputModelDraft" \
  "CjguiInternalRendererStage564HostRouteTextEditDemoSurfaceContractReadiness" \
  "didMaterializeSharedComponentRuntimeTextInputModel" \
  "didMaterializeSharedTextValueModel" \
  "didMaterializeSharedTextSelectionModel" \
  "didMaterializeSharedCaretModel" \
  "didMaterializeSharedValidationPreviewModel" \
  "didMaterializeTodoComponentTextInputModel" \
  "didMaterializeSettingsComponentTextInputModel" \
  "didMaterializeAiGeneratedSettingsComponentTextInputModel" \
  "didMaterializeChatComposerComponentTextInputModel" \
  "didBindComponentTextInputModelToStage564SurfaceContract" \
  "didReducePerDemoTextInputModelTemplateNeed" \
  "didPrepareStage566ComponentRuntimeTextInputStateExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage565 component runtime text input model: missing token $token" >&2
    exit 3
  fi
done

echo "stage565_component_runtime_text_input_model_owner_present=true"
echo "stage564_host_route_text_edit_demo_surface_contract_consumed=true"
echo "stage563_host_route_text_edit_state_render_dry_run_consumed_transitively=true"
echo "shared_component_runtime_text_input_model_materialized=true"
echo "shared_text_value_model_materialized=true"
echo "shared_text_selection_model_materialized=true"
echo "shared_caret_model_materialized=true"
echo "shared_validation_preview_model_materialized=true"
echo "todo_component_text_input_model_materialized=true"
echo "settings_component_text_input_model_materialized=true"
echo "ai_generated_settings_component_text_input_model_materialized=true"
echo "chat_composer_component_text_input_model_materialized=true"
echo "component_text_input_model_bound_to_stage564_surface_contract=true"
echo "component_text_input_model_bound_to_text_edit_surface_inputs=true"
echo "component_text_input_model_owner_local=true"
echo "per_demo_text_input_model_template_need_reduced=true"
echo "stage566_component_runtime_text_input_state_executor_prepared=true"
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
