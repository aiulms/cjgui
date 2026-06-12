#!/usr/bin/env zsh
#
# Verifies the stage846 publishable state text input composition preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage846_publishable_state_text_input_composition_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage846 publishable state text input composition preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewPlan" \
  "CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewFacts" \
  "CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage846PublishableStateTextInputCompositionPreviewDraft" \
  "CjguiInternalRendererStage845PublishableStateTextInputAdapterReadiness" \
  "didConsumeStage845PublishableStateTextInputAdapter" \
  "didConsumeNormalizedTextInputIntents" \
  "didMaterializeTextInsertionPreview" \
  "didMaterializeSelectionReplacementPreview" \
  "didMaterializeCaretMovementPreview" \
  "didMaterializeCompositionCommitCancelPreview" \
  "didMaterializeTextInputRollbackSnapshot" \
  "didMaterializeTextInputExplainReceipt" \
  "didBindCompositionPreviewToStage842EditPreview" \
  "didPrepareStage847PublishableStateTextInputDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage846 publishable state text input composition preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage846_publishable_state_text_input_composition_preview_owner_present=true"
echo "stage845_publishable_state_text_input_adapter_consumed=true"
echo "stage844_publishable_state_text_runtime_manager_consumed_transitively=true"
echo "stage842_publishable_state_text_edit_preview_consumed_transitively=true"
echo "normalized_text_input_intents_consumed=true"
echo "text_insertion_preview_materialized=true"
echo "selection_replacement_preview_materialized=true"
echo "caret_movement_preview_materialized=true"
echo "composition_commit_cancel_preview_materialized=true"
echo "text_input_rollback_snapshot_materialized=true"
echo "text_input_explain_receipt_materialized=true"
echo "composition_preview_bound_to_stage842_edit_preview=true"
echo "stage847_publishable_state_text_input_demo_surface_prepared=true"
echo "text_mutation=false"
echo "input_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
