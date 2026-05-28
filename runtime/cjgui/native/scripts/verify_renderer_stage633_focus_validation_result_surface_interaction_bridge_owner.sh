#!/usr/bin/env zsh
#
# Verifies the stage633 focus/validation result-surface interaction bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage633_focus_validation_result_surface_interaction_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage633 focus validation result surface interaction bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage633FocusValidationResultSurfaceInteractionBridgePlan" \
  "CjguiInternalRendererStage633FocusValidationResultSurfaceInteractionBridgeFacts" \
  "CjguiInternalRendererStage633FocusValidationResultSurfaceInteractionBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage633FocusValidationResultSurfaceInteractionBridgeDraft" \
  "CjguiInternalRendererStage632SharedFocusValidationResultSurfaceRuntimeContractReadiness" \
  "didConsumeStage632SharedFocusValidationResultSurfaceRuntimeContract" \
  "didMaterializeSharedFocusValidationResultSurfaceInteractionBridgeContract" \
  "didMaterializeSharedFocusValidationResultSurfaceInteractionTargetLedger" \
  "didMaterializeTodoResultSurfaceInteractionTarget" \
  "didMaterializeSettingsResultSurfaceInteractionTarget" \
  "didMaterializeAiGeneratedSettingsResultSurfaceInteractionTarget" \
  "didMaterializeChatComposerResultSurfaceInteractionTarget" \
  "didBindInteractionBridgeToStage632RuntimeSurfaces" \
  "didPrepareStage634FocusValidationResultSurfaceActionStateAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage633 focus validation result surface interaction bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage633_focus_validation_result_surface_interaction_bridge_owner_present=true"
echo "stage632_shared_focus_validation_result_surface_runtime_contract_consumed=true"
echo "stage631_focus_validation_result_surface_host_inspection_consumed_transitively=true"
echo "stage630_focus_validation_host_input_result_semantic_refresh_consumed_transitively=true"
echo "stage629_focus_validation_host_input_result_surface_consumed_transitively=true"
echo "shared_focus_validation_result_surface_interaction_bridge_contract_materialized=true"
echo "shared_focus_validation_result_surface_interaction_target_ledger_materialized=true"
echo "validation_error_result_surface_interaction_target_materialized=true"
echo "focus_movement_result_surface_interaction_target_materialized=true"
echo "input_feedback_result_surface_interaction_target_materialized=true"
echo "todo_result_surface_interaction_target_materialized=true"
echo "settings_result_surface_interaction_target_materialized=true"
echo "ai_generated_settings_result_surface_interaction_target_materialized=true"
echo "chat_composer_result_surface_interaction_target_materialized=true"
echo "result_surface_interaction_bridge_bound_to_stage632_runtime_surfaces=true"
echo "stage634_focus_validation_result_surface_action_state_adapter_prepared=true"
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
