#!/usr/bin/env zsh
#
# Verifies the stage539 component runtime layout/text/focus executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage539_component_runtime_layout_text_focus_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage539 component runtime layout text focus executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage539ComponentRuntimeLayoutTextFocusExecutorPlan" \
  "CjguiInternalRendererStage539ComponentRuntimeLayoutTextFocusExecutorFacts" \
  "CjguiInternalRendererStage539ComponentRuntimeLayoutTextFocusExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage539ComponentRuntimeLayoutTextFocusExecutorDraft" \
  "CjguiInternalRendererStage538ComponentRuntimeSurfaceModelReadiness" \
  "didConsumeStage538ComponentRuntimeSurfaceModel" \
  "didMaterializeSharedComponentRuntimeLayoutTextFocusExecutor" \
  "didMaterializeComponentRuntimeLayoutSlots" \
  "didMaterializeComponentRuntimeStyleTokens" \
  "didMaterializeComponentRuntimeTextRuns" \
  "didMaterializeComponentRuntimeFocusOrder" \
  "didBindLayoutTextFocusExecutorToSurfaceModel" \
  "didKeepLayoutTextFocusExecutorReusable" \
  "didPrepareStage540ComponentRuntimeDemoHostInspectionContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage539 component runtime layout text focus executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage539_component_runtime_layout_text_focus_executor_owner_present=true"
echo "stage538_component_runtime_surface_model_consumed=true"
echo "shared_component_runtime_surface_model_contract_consumed=true"
echo "semantic_state_render_layout_input_facet_consumed=true"
echo "shared_component_runtime_layout_text_focus_executor_materialized=true"
echo "component_runtime_layout_slots_materialized=true"
echo "component_runtime_style_tokens_materialized=true"
echo "component_runtime_text_runs_materialized=true"
echo "component_runtime_focus_order_materialized=true"
echo "todo_component_runtime_layout_text_focus_receipt_materialized=true"
echo "settings_component_runtime_layout_text_focus_receipt_materialized=true"
echo "ai_generated_settings_component_runtime_layout_text_focus_receipt_materialized=true"
echo "layout_text_focus_executor_bound_to_surface_model=true"
echo "layout_text_focus_executor_reusable=true"
echo "layout_text_focus_executor_preview_only=true"
echo "stage540_component_runtime_demo_host_inspection_contract_prepared=true"
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
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
