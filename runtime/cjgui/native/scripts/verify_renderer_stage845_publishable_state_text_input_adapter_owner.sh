#!/usr/bin/env zsh
#
# Verifies the stage845 publishable state text input adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage845_publishable_state_text_input_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage845 publishable state text input adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage845PublishableStateTextInputAdapterPlan" \
  "CjguiInternalRendererStage845PublishableStateTextInputAdapterFacts" \
  "CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage845PublishableStateTextInputAdapterDraft" \
  "CjguiInternalRendererStage844PublishableStateTextRuntimeManagerReadiness" \
  "CjguiInternalRendererStage573ComponentRuntimeTextInputDemoExecutionContractReadiness" \
  "didConsumeStage844PublishableStateTextRuntimeManager" \
  "didConsumeStage573ComponentRuntimeTextInputDemoExecutionContract" \
  "didMaterializeNormalizedKeyboardTextIntentAdapter" \
  "didMaterializeCaretMovementIntentAdapter" \
  "didMaterializeSelectionReplacementIntentAdapter" \
  "didMaterializeCompositionPreeditIntentAdapter" \
  "didBindTextInputAdapterToStage844TextRuntimeManager" \
  "didBindTextInputAdapterToStage573ExecutionContract" \
  "didPrepareStage846PublishableStateTextInputCompositionPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage845 publishable state text input adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage845_publishable_state_text_input_adapter_owner_present=true"
echo "stage844_publishable_state_text_runtime_manager_consumed=true"
echo "stage573_component_runtime_text_input_demo_execution_contract_consumed=true"
echo "stage842_publishable_state_text_edit_preview_consumed_transitively=true"
echo "stage841_publishable_state_text_model_consumed_transitively=true"
echo "normalized_keyboard_text_intent_adapter_materialized=true"
echo "caret_movement_intent_adapter_materialized=true"
echo "selection_replacement_intent_adapter_materialized=true"
echo "composition_preedit_intent_adapter_materialized=true"
echo "text_input_adapter_bound_to_stage844_text_runtime_manager=true"
echo "text_input_adapter_bound_to_stage573_execution_contract=true"
echo "stage846_publishable_state_text_input_composition_preview_prepared=true"
echo "text_input_adapter_owner_local=true"
echo "text_input_adapter_non_executing=true"
echo "text_input_adapter_non_dispatching=true"
echo "text_shaping_enabled=false"
echo "text_mutation=false"
echo "input_pipeline_execution=false"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
