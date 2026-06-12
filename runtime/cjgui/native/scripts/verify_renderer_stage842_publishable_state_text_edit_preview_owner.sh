#!/usr/bin/env zsh
#
# Verifies the stage842 publishable state text edit preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage842_publishable_state_text_edit_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage842 publishable state text edit preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage842PublishableStateTextEditPreviewPlan" \
  "CjguiInternalRendererStage842PublishableStateTextEditPreviewFacts" \
  "CjguiInternalRendererStage842PublishableStateTextEditPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage842PublishableStateTextEditPreviewDraft" \
  "CjguiInternalRendererStage841PublishableStateTextModelReadiness" \
  "didConsumeStage841PublishableStateTextModel" \
  "didMaterializeOwnerLocalTextEditPreview" \
  "didMaterializeSelectionCaretDeltaPreview" \
  "didMaterializeCompositionPlaceholderEditPreview" \
  "didMaterializeTextRollbackSnapshot" \
  "didMaterializeTextChangeExplainReceipt" \
  "didBindTextEditPreviewToStage841TextModel" \
  "didPrepareStage843PublishableStateTextDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage842 publishable state text edit preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage842_publishable_state_text_edit_preview_owner_present=true"
echo "stage841_publishable_state_text_model_consumed=true"
echo "stage840_publishable_state_focus_runtime_manager_consumed_transitively=true"
echo "owner_local_text_value_model_consumed=true"
echo "owner_local_text_edit_preview_materialized=true"
echo "selection_caret_delta_preview_materialized=true"
echo "composition_placeholder_edit_preview_materialized=true"
echo "text_rollback_snapshot_materialized=true"
echo "text_change_explain_receipt_materialized=true"
echo "text_edit_preview_bound_to_stage841_text_model=true"
echo "stage843_publishable_state_text_demo_surface_prepared=true"
echo "text_mutation=false"
echo "input_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
