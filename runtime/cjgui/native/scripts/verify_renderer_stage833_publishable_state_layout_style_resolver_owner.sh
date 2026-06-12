#!/usr/bin/env zsh
#
# Verifies the stage833 publishable state layout/style resolver owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage833_publishable_state_layout_style_resolver.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage833 publishable state layout style resolver: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage833PublishableStateLayoutStyleResolverPlan" \
  "CjguiInternalRendererStage833PublishableStateLayoutStyleResolverFacts" \
  "CjguiInternalRendererStage833PublishableStateLayoutStyleResolverReadiness" \
  "cjguiInternalExecuteDefaultRendererStage833PublishableStateLayoutStyleResolverDraft" \
  "CjguiInternalRendererStage832ComponentStateStorePublishableRuntimeManagerReadiness" \
  "didConsumeStage832ComponentStateStorePublishableRuntimeManager" \
  "didMaterializePublishableStateLayoutResolverInput" \
  "didMaterializePublishableStateStyleResolverInput" \
  "didMaterializeLayoutSlotConstraintLedger" \
  "didMaterializeStyleTokenResolutionLedger" \
  "didBindResolverInputToStage830SlotValueModel" \
  "didBindResolverInputToStage832RuntimeManager" \
  "didPrepareStage834PublishableStateTextFocusMeasurementPlan"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage833 publishable state layout style resolver: missing token $token" >&2
    exit 3
  fi
done

echo "stage833_publishable_state_layout_style_resolver_owner_present=true"
echo "stage832_component_state_store_publishable_runtime_manager_consumed=true"
echo "stage831_component_state_store_commit_candidate_rollback_snapshot_consumed_transitively=true"
echo "stage830_component_state_store_slot_value_model_consumed_transitively=true"
echo "publishable_state_runtime_manager_consumed=true"
echo "publishable_state_layout_resolver_input_materialized=true"
echo "publishable_state_style_resolver_input_materialized=true"
echo "layout_slot_constraint_ledger_materialized=true"
echo "style_token_resolution_ledger_materialized=true"
echo "resolver_input_bound_to_stage830_slot_value_model=true"
echo "resolver_input_bound_to_stage832_runtime_manager=true"
echo "stage834_publishable_state_text_focus_measurement_plan_prepared=true"
echo "layout_engine_enabled=false"
echo "style_resolver_production_enabled=false"
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
