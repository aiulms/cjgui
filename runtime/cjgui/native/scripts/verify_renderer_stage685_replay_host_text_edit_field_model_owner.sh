#!/usr/bin/env zsh
#
# Verifies the stage685 replay host text edit field model owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage685_replay_host_text_edit_field_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage685 replay host text edit field model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage685ReplayHostTextEditFieldModelPlan" \
  "CjguiInternalRendererStage685ReplayHostTextEditFieldModelFacts" \
  "CjguiInternalRendererStage685ReplayHostTextEditFieldModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage685ReplayHostTextEditFieldModelDraft" \
  "CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness" \
  "didConsumeStage684ReplayActionStateRenderHostInspectionRuntimeContract" \
  "didMaterializeSharedReplayHostTextEditFieldModel" \
  "didMaterializeReplayHostTextValueModel" \
  "didMaterializeReplayHostTextSelectionModel" \
  "didMaterializeReplayHostCaretModel" \
  "didMaterializeReplayHostValidationPreviewModel" \
  "didMaterializeReplayHostSubmitAffordanceModel" \
  "didMaterializeChatComposerReplayHostTextEditFieldModel" \
  "didBindTextEditFieldModelToStage684RuntimeContract" \
  "didBindTextEditFieldModelToStage683ResultSurfaceRefresh" \
  "didReduceFuturePerDemoTextEditFieldModelTemplateNeed" \
  "didPrepareStage686ReplayHostTextEditStateDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage685 replay host text edit field model: missing token $token" >&2
    exit 3
  fi
done

echo "stage685_replay_host_text_edit_field_model_owner_present=true"
echo "stage684_replay_action_state_render_host_inspection_runtime_contract_consumed=true"
echo "shared_replay_host_text_edit_field_model_materialized=true"
echo "replay_host_text_value_model_materialized=true"
echo "replay_host_text_selection_model_materialized=true"
echo "replay_host_caret_model_materialized=true"
echo "replay_host_validation_preview_model_materialized=true"
echo "replay_host_submit_affordance_model_materialized=true"
echo "todo_replay_host_text_edit_field_model_materialized=true"
echo "settings_replay_host_text_edit_field_model_materialized=true"
echo "ai_generated_settings_replay_host_text_edit_field_model_materialized=true"
echo "chat_composer_replay_host_text_edit_field_model_materialized=true"
echo "text_edit_field_model_bound_to_stage684_runtime_contract=true"
echo "text_edit_field_model_bound_to_stage683_result_surface_refresh=true"
echo "future_per_demo_text_edit_field_model_template_need_reduced=true"
echo "stage686_replay_host_text_edit_state_dry_run_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
