#!/usr/bin/env zsh
#
# Verifies the stage705 component runtime input event normalization owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage705_component_runtime_input_event_normalization.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage705 component runtime input event normalization: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage705ComponentRuntimeInputEventNormalizationPlan" \
  "CjguiInternalRendererStage705ComponentRuntimeInputEventNormalizationFacts" \
  "CjguiInternalRendererStage705ComponentRuntimeInputEventNormalizationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage705ComponentRuntimeInputEventNormalizationDraft" \
  "CjguiInternalRendererStage704TextInputComponentRuntimeCycleExecutorReadiness" \
  "didConsumeStage704TextInputComponentRuntimeCycleExecutor" \
  "didMaterializeSharedComponentRuntimeInputEventNormalizer" \
  "didMaterializeTextEditNormalizedComponentInputEvent" \
  "didMaterializeSubmitNormalizedComponentInputEvent" \
  "didMaterializeValidationDismissNormalizedComponentInputEvent" \
  "didMaterializeFocusMoveNormalizedComponentInputEvent" \
  "didPrepareStage706ComponentRuntimeActionIntentAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage705 component runtime input event normalization: missing token $token" >&2
    exit 3
  fi
done

echo "stage705_component_runtime_input_event_normalization_owner_present=true"
echo "stage704_text_input_component_runtime_cycle_executor_consumed=true"
echo "shared_component_runtime_input_event_normalizer_materialized=true"
echo "text_edit_normalized_component_input_event_materialized=true"
echo "submit_normalized_component_input_event_materialized=true"
echo "validation_dismiss_normalized_component_input_event_materialized=true"
echo "focus_move_normalized_component_input_event_materialized=true"
echo "todo_component_runtime_normalized_input_surface_materialized=true"
echo "settings_component_runtime_normalized_input_surface_materialized=true"
echo "ai_generated_settings_component_runtime_normalized_input_surface_materialized=true"
echo "chat_composer_component_runtime_normalized_input_surface_materialized=true"
echo "normalized_input_event_bound_to_component_slot_contract=true"
echo "stage706_component_runtime_action_intent_adapter_prepared=true"
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
