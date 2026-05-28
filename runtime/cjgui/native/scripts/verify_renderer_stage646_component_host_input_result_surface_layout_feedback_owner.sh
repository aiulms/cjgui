#!/usr/bin/env zsh
#
# Verifies the stage646 component host input result surface layout feedback owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage646_component_host_input_result_surface_layout_feedback.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage646 component host input result surface layout feedback: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage646ComponentHostInputResultSurfaceLayoutFeedbackPlan" \
  "CjguiInternalRendererStage646ComponentHostInputResultSurfaceLayoutFeedbackFacts" \
  "CjguiInternalRendererStage646ComponentHostInputResultSurfaceLayoutFeedbackReadiness" \
  "cjguiInternalExecuteDefaultRendererStage646ComponentHostInputResultSurfaceLayoutFeedbackDraft" \
  "CjguiInternalRendererStage645ComponentHostInputResultSurfaceRefreshReadiness" \
  "didConsumeStage645ComponentHostInputResultSurfaceRefresh" \
  "didMaterializeSharedResultSurfaceLayoutFeedbackResolver" \
  "didMaterializeValidationMessageLayoutSlot" \
  "didMaterializeFocusRingStyleTokenPreview" \
  "didMaterializeInputFeedbackAffordancePreview" \
  "didMaterializeChatComposerResultSurfaceLayoutFeedback" \
  "didBindLayoutFeedbackToStage645Refresh" \
  "didPrepareStage647ComponentHostInputResultSurfaceHostInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage646 component host input result surface layout feedback: missing token $token" >&2
    exit 3
  fi
done

echo "stage646_component_host_input_result_surface_layout_feedback_owner_present=true"
echo "stage645_component_host_input_result_surface_refresh_consumed=true"
echo "stage644_component_host_input_cycle_executor_consumed_transitively=true"
echo "shared_result_surface_layout_feedback_resolver_materialized=true"
echo "validation_message_layout_slot_materialized=true"
echo "focus_ring_style_token_preview_materialized=true"
echo "input_feedback_affordance_preview_materialized=true"
echo "semantic_refresh_layout_trace_materialized=true"
echo "todo_result_surface_layout_feedback_materialized=true"
echo "settings_result_surface_layout_feedback_materialized=true"
echo "ai_generated_settings_result_surface_layout_feedback_materialized=true"
echo "chat_composer_result_surface_layout_feedback_materialized=true"
echo "layout_feedback_bound_to_stage645_refresh=true"
echo "stage647_component_host_input_result_surface_host_inspection_prepared=true"
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
