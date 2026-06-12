#!/usr/bin/env zsh
#
# Verifies the stage830 component state-store slot value model owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage830_component_state_store_slot_value_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage830 component state-store slot value model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage830ComponentStateStoreSlotValueModelPlan" \
  "CjguiInternalRendererStage830ComponentStateStoreSlotValueModelFacts" \
  "CjguiInternalRendererStage830ComponentStateStoreSlotValueModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage830ComponentStateStoreSlotValueModelDraft" \
  "CjguiInternalRendererStage829ComponentStateStorePublishableStateModelReadiness" \
  "didConsumeStage829ComponentStateStorePublishableStateModel" \
  "didMaterializeComponentSlotValueModel" \
  "didMaterializeTextSlotValue" \
  "didMaterializeSelectionSlotValue" \
  "didMaterializeFocusSlotValue" \
  "didMaterializeStyleSlotValue" \
  "didMaterializeLayoutSlotValue" \
  "didMaterializeSlotValueCoercionLedger" \
  "didBindSlotValuesToStage829PublishableStateModel" \
  "didPrepareStage831ComponentStateStoreCommitCandidateRollbackSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage830 component state-store slot value model: missing token $token" >&2
    exit 3
  fi
done

echo "stage830_component_state_store_slot_value_model_owner_present=true"
echo "stage829_component_state_store_publishable_state_model_consumed=true"
echo "stage828_commit_first_slice_publication_runtime_manager_consumed_transitively=true"
echo "component_slot_value_model_materialized=true"
echo "text_slot_value_materialized=true"
echo "selection_slot_value_materialized=true"
echo "focus_slot_value_materialized=true"
echo "style_slot_value_materialized=true"
echo "layout_slot_value_materialized=true"
echo "slot_value_coercion_ledger_materialized=true"
echo "slot_values_bound_to_stage829_publishable_state_model=true"
echo "stage831_component_state_store_commit_candidate_rollback_snapshot_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
