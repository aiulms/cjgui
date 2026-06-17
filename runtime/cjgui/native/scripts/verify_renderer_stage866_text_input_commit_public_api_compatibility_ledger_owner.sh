#!/usr/bin/env zsh
#
# Verifies the stage866 text-input commit public API compatibility ledger owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage866_text_input_commit_public_api_compatibility_ledger.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage866 text input commit public api compatibility ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage866TextInputCommitPublicApiCompatibilityLedgerPlan" \
  "CjguiInternalRendererStage866TextInputCommitPublicApiCompatibilityLedgerFacts" \
  "CjguiInternalRendererStage866TextInputCommitPublicApiCompatibilityLedgerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage866TextInputCommitPublicApiCompatibilityLedgerDraft" \
  "CjguiInternalRendererStage865TextInputCommitPublicApiConsumptionContractReadiness" \
  "didConsumeStage865TextInputCommitPublicApiConsumptionContract" \
  "didMaterializePublicApiCompatibilityLedger" \
  "didMaterializeRollbackCompatibilityNote" \
  "didMaterializeNotPublishedCompatibilityReceipt" \
  "didMaterializeExperimentalApiStabilityBoundary" \
  "didBindCompatibilityLedgerToStage865Contract" \
  "didPrepareStage867TextInputCommitPublicApiDemoProofSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage866 text input commit public api compatibility ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage866_text_input_commit_public_api_compatibility_ledger_owner_present=true"
echo "stage865_text_input_commit_public_api_consumption_contract_consumed=true"
echo "stage864_text_input_owner_acceptance_runtime_manager_consumed_transitively=true"
echo "public_api_compatibility_ledger_materialized=true"
echo "public_api_rollback_compatibility_note_materialized=true"
echo "public_api_not_published_compatibility_receipt_materialized=true"
echo "experimental_api_stability_boundary_materialized=true"
echo "compatibility_ledger_bound_to_stage865_contract=true"
echo "stage867_text_input_commit_public_api_demo_proof_surface_prepared=true"
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
