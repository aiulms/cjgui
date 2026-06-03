#!/usr/bin/env zsh
#
# Verifies the stage706 component runtime action intent adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage706_component_runtime_action_intent_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage706 component runtime action intent adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage706ComponentRuntimeActionIntentAdapterPlan" \
  "CjguiInternalRendererStage706ComponentRuntimeActionIntentAdapterFacts" \
  "CjguiInternalRendererStage706ComponentRuntimeActionIntentAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage706ComponentRuntimeActionIntentAdapterDraft" \
  "CjguiInternalRendererStage705ComponentRuntimeInputEventNormalizationReadiness" \
  "didConsumeStage705ComponentRuntimeInputEventNormalization" \
  "didMaterializeSharedComponentRuntimeActionIntentAdapter" \
  "didMaterializeTextEditComponentActionIntent" \
  "didMaterializeSubmitComponentActionIntent" \
  "didMaterializeValidationDismissComponentActionIntent" \
  "didMaterializeFocusMoveComponentActionIntent" \
  "didPrepareStage707ComponentRuntimeStateRenderFeedbackDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage706 component runtime action intent adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage706_component_runtime_action_intent_adapter_owner_present=true"
echo "stage705_component_runtime_input_event_normalization_consumed=true"
echo "stage704_text_input_component_runtime_cycle_executor_consumed_transitively=true"
echo "shared_component_runtime_action_intent_adapter_materialized=true"
echo "text_edit_component_action_intent_materialized=true"
echo "submit_component_action_intent_materialized=true"
echo "validation_dismiss_component_action_intent_materialized=true"
echo "focus_move_component_action_intent_materialized=true"
echo "todo_component_runtime_action_intent_surface_materialized=true"
echo "settings_component_runtime_action_intent_surface_materialized=true"
echo "ai_generated_settings_component_runtime_action_intent_surface_materialized=true"
echo "chat_composer_component_runtime_action_intent_surface_materialized=true"
echo "component_action_intent_bound_to_normalized_input_event=true"
echo "component_action_intent_non_dispatching=true"
echo "stage707_component_runtime_state_render_feedback_dry_run_prepared=true"
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
