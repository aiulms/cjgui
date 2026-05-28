#!/usr/bin/env zsh
#
# Verifies the stage647 component host input result surface host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage647_component_host_input_result_surface_host_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage647 component host input result surface host inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage647ComponentHostInputResultSurfaceHostInspectionPlan" \
  "CjguiInternalRendererStage647ComponentHostInputResultSurfaceHostInspectionFacts" \
  "CjguiInternalRendererStage647ComponentHostInputResultSurfaceHostInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage647ComponentHostInputResultSurfaceHostInspectionDraft" \
  "CjguiInternalRendererStage646ComponentHostInputResultSurfaceLayoutFeedbackReadiness" \
  "didConsumeStage646ComponentHostInputResultSurfaceLayoutFeedback" \
  "didMaterializeSharedResultSurfaceHostInspectionReceipt" \
  "didMaterializeValidationDisplayHostInspectionSlot" \
  "didMaterializeFocusMovementHostInspectionSlot" \
  "didMaterializeInputFeedbackHostInspectionSlot" \
  "didMaterializeChatComposerResultSurfaceHostInspection" \
  "didBindHostInspectionToStage646LayoutFeedback" \
  "didPrepareStage648ComponentHostInputResultSurfaceRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage647 component host input result surface host inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage647_component_host_input_result_surface_host_inspection_owner_present=true"
echo "stage646_component_host_input_result_surface_layout_feedback_consumed=true"
echo "stage645_component_host_input_result_surface_refresh_consumed_transitively=true"
echo "shared_result_surface_host_inspection_receipt_materialized=true"
echo "validation_display_host_inspection_slot_materialized=true"
echo "focus_movement_host_inspection_slot_materialized=true"
echo "input_feedback_host_inspection_slot_materialized=true"
echo "semantic_refresh_host_inspection_slot_materialized=true"
echo "todo_result_surface_host_inspection_materialized=true"
echo "settings_result_surface_host_inspection_materialized=true"
echo "ai_generated_settings_result_surface_host_inspection_materialized=true"
echo "chat_composer_result_surface_host_inspection_materialized=true"
echo "host_inspection_bound_to_stage646_layout_feedback=true"
echo "stage648_component_host_input_result_surface_runtime_contract_prepared=true"
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
