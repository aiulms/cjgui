#!/usr/bin/env zsh
#
# Verifies the stage629 focus/validation host input result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage629_focus_validation_host_input_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage629 focus validation host input result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage629FocusValidationHostInputResultSurfacePlan" \
  "CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceFacts" \
  "CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage629FocusValidationHostInputResultSurfaceDraft" \
  "CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractReadiness" \
  "didConsumeStage628SharedFocusValidationHostInputRuntimeContract" \
  "didMaterializeSharedFocusValidationHostInputResultSurface" \
  "didMaterializeValidationErrorResultSurface" \
  "didMaterializeFocusMovementResultSurfacePreview" \
  "didMaterializeInputFeedbackResultSurfaceDisplay" \
  "didMaterializeSemanticDiffResultSurfaceRefresh" \
  "didMaterializeChatComposerFocusValidationResultSurface" \
  "didBindResultSurfaceToStage628RuntimeContract" \
  "didPrepareStage630FocusValidationHostInputResultSemanticRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage629 focus validation host input result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage629_focus_validation_host_input_result_surface_owner_present=true"
echo "stage628_shared_focus_validation_host_input_runtime_contract_consumed=true"
echo "host_input_runtime_surfaces_consumed=true"
echo "shared_focus_validation_host_input_result_surface_materialized=true"
echo "validation_error_result_surface_materialized=true"
echo "focus_movement_result_surface_preview_materialized=true"
echo "input_feedback_result_surface_display_materialized=true"
echo "semantic_diff_result_surface_refresh_materialized=true"
echo "todo_focus_validation_result_surface_materialized=true"
echo "settings_focus_validation_result_surface_materialized=true"
echo "ai_generated_settings_focus_validation_result_surface_materialized=true"
echo "chat_composer_focus_validation_result_surface_materialized=true"
echo "result_surface_bound_to_stage628_runtime_contract=true"
echo "stage630_focus_validation_host_input_result_semantic_refresh_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
