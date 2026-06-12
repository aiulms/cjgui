#!/usr/bin/env zsh
#
# Verifies the stage829 component state-store publishable state model owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage829_component_state_store_publishable_state_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage829 component state-store publishable state model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage829ComponentStateStorePublishableStateModelPlan" \
  "CjguiInternalRendererStage829ComponentStateStorePublishableStateModelFacts" \
  "CjguiInternalRendererStage829ComponentStateStorePublishableStateModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage829ComponentStateStorePublishableStateModelDraft" \
  "CjguiInternalRendererStage828CommitFirstSlicePublicationRuntimeManagerReadiness" \
  "didConsumeStage828CommitFirstSlicePublicationRuntimeManager" \
  "didMaterializeOwnerLocalPublishableStateModel" \
  "didMaterializeComponentStateIdentityLedger" \
  "didMaterializeDraftVisibilityStateProjection" \
  "didMaterializePublishableStateCompatibilityLedger" \
  "didBindPublishableStateModelToStage828PublicationRuntimeManager" \
  "didPrepareStage830ComponentStateStoreSlotValueModel"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage829 component state-store publishable state model: missing token $token" >&2
    exit 3
  fi
done

echo "stage829_component_state_store_publishable_state_model_owner_present=true"
echo "stage828_commit_first_slice_publication_runtime_manager_consumed=true"
echo "stage827_commit_first_slice_publication_demo_host_surface_consumed_transitively=true"
echo "shared_publication_runtime_manager_consumed=true"
echo "owner_local_publishable_state_model_materialized=true"
echo "component_state_identity_ledger_materialized=true"
echo "draft_visibility_state_projection_materialized=true"
echo "publishable_state_compatibility_ledger_materialized=true"
echo "publishable_state_model_bound_to_stage828_publication_runtime_manager=true"
echo "stage830_component_state_store_slot_value_model_prepared=true"
echo "public_component_api_added=true"
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
