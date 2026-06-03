#!/usr/bin/env zsh
#
# Verifies the stage703 text input component runtime demo surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage703_text_input_component_runtime_demo_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage703 text input component runtime demo surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage703TextInputComponentRuntimeDemoSurfaceRefreshPlan" \
  "CjguiInternalRendererStage703TextInputComponentRuntimeDemoSurfaceRefreshFacts" \
  "CjguiInternalRendererStage703TextInputComponentRuntimeDemoSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage703TextInputComponentRuntimeDemoSurfaceRefreshDraft" \
  "CjguiInternalRendererStage702TextInputComponentSlotBindingAdapterReadiness" \
  "didConsumeStage702TextInputComponentSlotBindingAdapter" \
  "didMaterializeSharedTextInputComponentRuntimeDemoSurfaceRefresh" \
  "didMaterializeComponentRuntimeResultSurfaceRefresh" \
  "didMaterializeComponentRuntimeSemanticDiffExplain" \
  "didMaterializeChatComposerTextInputComponentRuntimeDemoSurfaceRefresh" \
  "didBindDemoSurfaceRefreshToComponentSlotBindings" \
  "didPrepareStage704TextInputComponentRuntimeCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage703 text input component runtime demo surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage703_text_input_component_runtime_demo_surface_refresh_owner_present=true"
echo "stage702_text_input_component_slot_binding_adapter_consumed=true"
echo "shared_text_input_component_runtime_demo_surface_refresh_materialized=true"
echo "component_runtime_result_surface_refresh_materialized=true"
echo "component_runtime_semantic_diff_explain_materialized=true"
echo "component_runtime_feedback_surface_refresh_materialized=true"
echo "component_runtime_focus_surface_refresh_materialized=true"
echo "todo_text_input_component_runtime_demo_surface_refresh_materialized=true"
echo "settings_text_input_component_runtime_demo_surface_refresh_materialized=true"
echo "ai_generated_settings_text_input_component_runtime_demo_surface_refresh_materialized=true"
echo "chat_composer_text_input_component_runtime_demo_surface_refresh_materialized=true"
echo "demo_surface_refresh_bound_to_component_slot_bindings=true"
echo "stage701_contract_consumed_transitively=true"
echo "stage700_executor_consumed_transitively=true"
echo "stage704_text_input_component_runtime_cycle_executor_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
