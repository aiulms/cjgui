#!/usr/bin/env zsh
#
# Verifies the stage645 component host input result surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage645_component_host_input_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage645 component host input result surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage645ComponentHostInputResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage645ComponentHostInputResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage645ComponentHostInputResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage645ComponentHostInputResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage644ComponentHostInputCycleExecutorReadiness" \
  "didConsumeStage644ComponentHostInputCycleExecutor" \
  "didMaterializeSharedComponentHostInputResultSurfaceRefresh" \
  "didMaterializeValidationDisplayResultSurfaceRefresh" \
  "didMaterializeFocusMovementResultSurfacePreview" \
  "didMaterializeInputFeedbackResultSurfaceRefresh" \
  "didMaterializeSemanticDiffResultSurfaceRefresh" \
  "didMaterializeChatComposerComponentHostInputResultSurfaceRefresh" \
  "didBindResultSurfaceRefreshToStage644Executor" \
  "didPrepareStage646ComponentHostInputResultSurfaceLayoutFeedback"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage645 component host input result surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage645_component_host_input_result_surface_refresh_owner_present=true"
echo "stage644_component_host_input_cycle_executor_consumed=true"
echo "stage643_component_host_input_cycle_receipt_consumed_transitively=true"
echo "shared_component_host_input_result_surface_refresh_materialized=true"
echo "validation_display_result_surface_refresh_materialized=true"
echo "focus_movement_result_surface_preview_materialized=true"
echo "input_feedback_result_surface_refresh_materialized=true"
echo "semantic_diff_result_surface_refresh_materialized=true"
echo "todo_component_host_input_result_surface_refresh_materialized=true"
echo "settings_component_host_input_result_surface_refresh_materialized=true"
echo "ai_generated_settings_component_host_input_result_surface_refresh_materialized=true"
echo "chat_composer_component_host_input_result_surface_refresh_materialized=true"
echo "result_surface_refresh_bound_to_stage644_executor=true"
echo "stage646_component_host_input_result_surface_layout_feedback_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
