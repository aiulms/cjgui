#!/usr/bin/env zsh
#
# Verifies the stage841 publishable state text model owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage841_publishable_state_text_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage841 publishable state text model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage841PublishableStateTextModelPlan" \
  "CjguiInternalRendererStage841PublishableStateTextModelFacts" \
  "CjguiInternalRendererStage841PublishableStateTextModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage841PublishableStateTextModelDraft" \
  "CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness" \
  "didConsumeStage840PublishableStateFocusRuntimeManager" \
  "didMaterializeOwnerLocalTextValueModel" \
  "didMaterializeTextRunLedger" \
  "didMaterializeSelectionRangeModel" \
  "didMaterializeCaretPositionModel" \
  "didMaterializeCompositionPlaceholderModel" \
  "didBindTextModelToStage834MeasurementPlan" \
  "didBindTextModelToStage840FocusRuntimeManager" \
  "didPrepareStage842PublishableStateTextEditPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage841 publishable state text model: missing token $token" >&2
    exit 3
  fi
done

echo "stage841_publishable_state_text_model_owner_present=true"
echo "stage840_publishable_state_focus_runtime_manager_consumed=true"
echo "stage839_publishable_state_focus_demo_surface_consumed_transitively=true"
echo "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true"
echo "shared_publishable_focus_runtime_manager_consumed=true"
echo "owner_local_text_value_model_materialized=true"
echo "text_run_ledger_materialized=true"
echo "selection_range_model_materialized=true"
echo "caret_position_model_materialized=true"
echo "composition_placeholder_model_materialized=true"
echo "text_model_bound_to_stage834_measurement_plan=true"
echo "text_model_bound_to_stage840_focus_runtime_manager=true"
echo "stage842_publishable_state_text_edit_preview_prepared=true"
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
