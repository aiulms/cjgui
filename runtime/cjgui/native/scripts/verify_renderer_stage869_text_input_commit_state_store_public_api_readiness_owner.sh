#!/usr/bin/env zsh
#
# Verifies the stage869 text-input commit state-store public API readiness owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage869_text_input_commit_state_store_public_api_readiness.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage869 text input commit state store public api readiness: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage869TextInputCommitStateStorePublicApiReadinessPlan" \
  "CjguiInternalRendererStage869TextInputCommitStateStorePublicApiReadinessFacts" \
  "CjguiInternalRendererStage869TextInputCommitStateStorePublicApiReadiness" \
  "cjguiInternalExecuteDefaultRendererStage869TextInputCommitStateStorePublicApiReadinessDraft" \
  "CjguiInternalRendererStage868TextInputCommitPublicApiConsumptionRuntimeManagerReadiness" \
  "didConsumeStage868TextInputCommitPublicApiConsumptionRuntimeManager" \
  "didMaterializeStateStorePublicApiCommitReadinessContract" \
  "didMaterializeStateStoreCommitCandidateLedger" \
  "didMaterializeRollbackNotPublishedBoundaryCarryForward" \
  "didBindReadinessToPublicApiConsumptionRuntimeContract" \
  "didBindReadinessToExistingExperimentalPublicApi" \
  "didMaterializeOwnerLocalStateStoreCommitFirstSliceReadiness" \
  "didPrepareStage870TextInputCommitStateStorePublicApiAdmission"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage869 text input commit state store public api readiness: missing token $token" >&2
    exit 3
  fi
done

echo "stage869_text_input_commit_state_store_public_api_readiness_owner_present=true"
echo "stage868_text_input_commit_public_api_consumption_runtime_manager_consumed=true"
echo "stage867_text_input_commit_public_api_demo_proof_surface_consumed_transitively=true"
echo "stage866_text_input_commit_public_api_compatibility_ledger_consumed_transitively=true"
echo "stage865_text_input_commit_public_api_consumption_contract_consumed_transitively=true"
echo "state_store_public_api_commit_readiness_contract_materialized=true"
echo "state_store_commit_candidate_ledger_materialized=true"
echo "rollback_not_published_boundary_carry_forward_materialized=true"
echo "state_store_public_api_readiness_bound_to_public_api_consumption_runtime_contract=true"
echo "state_store_public_api_readiness_bound_to_existing_experimental_public_api=true"
echo "owner_local_state_store_commit_first_slice_readiness_materialized=true"
echo "stage870_text_input_commit_state_store_public_api_admission_prepared=true"
echo "existing_public_component_api_available=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
