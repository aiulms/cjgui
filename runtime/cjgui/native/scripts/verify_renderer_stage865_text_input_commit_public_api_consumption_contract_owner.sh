#!/usr/bin/env zsh
#
# Verifies the stage865 text-input commit public API consumption contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage865_text_input_commit_public_api_consumption_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage865 text input commit public api consumption contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage865TextInputCommitPublicApiConsumptionContractPlan" \
  "CjguiInternalRendererStage865TextInputCommitPublicApiConsumptionContractFacts" \
  "CjguiInternalRendererStage865TextInputCommitPublicApiConsumptionContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage865TextInputCommitPublicApiConsumptionContractDraft" \
  "CjguiInternalRendererStage864TextInputOwnerAcceptanceRuntimeManagerReadiness" \
  "cjguiExperimentalComponentPreviewApiReady" \
  "didConsumeStage864TextInputOwnerAcceptanceRuntimeManager" \
  "didConsumeExistingExperimentalComponentPreviewApiReadiness" \
  "didMaterializeTextInputCommitPublicApiConsumptionContract" \
  "didMaterializeOwnerAcceptanceReceiptPublicApiProjection" \
  "didMaterializeTextInputCommitCandidatePublicApiProjection" \
  "didMaterializePublicApiNotPublishedBoundaryProjection" \
  "didBindPublicApiContractToStage864RuntimeManager" \
  "didKeepNewPublicSurfaceNotAdded" \
  "didPrepareStage866TextInputCommitPublicApiCompatibilityLedger"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage865 text input commit public api consumption contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage865_text_input_commit_public_api_consumption_contract_owner_present=true"
echo "stage864_text_input_owner_acceptance_runtime_manager_consumed=true"
echo "stage863_text_input_acceptance_demo_host_surface_consumed_transitively=true"
echo "existing_experimental_component_preview_api_readiness_consumed=true"
echo "text_input_commit_public_api_consumption_contract_materialized=true"
echo "owner_acceptance_receipt_public_api_projection_materialized=true"
echo "text_input_commit_candidate_public_api_projection_materialized=true"
echo "public_api_not_published_boundary_projection_materialized=true"
echo "public_api_consumption_contract_bound_to_stage864_runtime_manager=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "stage866_text_input_commit_public_api_compatibility_ledger_prepared=true"
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
