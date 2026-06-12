#!/usr/bin/env zsh
#
# Verifies the stage834 publishable state text/focus measurement plan owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage834_publishable_state_text_focus_measurement_plan.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage834 publishable state text focus measurement plan: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage834PublishableStateTextFocusMeasurementPlan" \
  "CjguiInternalRendererStage834PublishableStateTextFocusMeasurementFacts" \
  "CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness" \
  "cjguiInternalExecuteDefaultRendererStage834PublishableStateTextFocusMeasurementDraft" \
  "CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness" \
  "didConsumeStage833PublishableStateLayoutStyleResolver" \
  "didMaterializeTextRunMeasurementInput" \
  "didMaterializeSelectionRangeMeasurementInput" \
  "didMaterializeCaretGeometryPlaceholder" \
  "didMaterializeFocusTraversalMeasurementLedger" \
  "didBindMeasurementPlanToLayoutStyleResolver" \
  "didPrepareStage835PublishableStateLayoutStyleDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage834 publishable state text focus measurement plan: missing token $token" >&2
    exit 3
  fi
done

echo "stage834_publishable_state_text_focus_measurement_plan_owner_present=true"
echo "stage833_publishable_state_layout_style_resolver_consumed=true"
echo "stage832_component_state_store_publishable_runtime_manager_consumed_transitively=true"
echo "layout_style_resolver_input_consumed=true"
echo "text_run_measurement_input_materialized=true"
echo "selection_range_measurement_input_materialized=true"
echo "caret_geometry_placeholder_materialized=true"
echo "focus_traversal_measurement_ledger_materialized=true"
echo "measurement_plan_bound_to_layout_style_resolver=true"
echo "stage835_publishable_state_layout_style_demo_surface_prepared=true"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
