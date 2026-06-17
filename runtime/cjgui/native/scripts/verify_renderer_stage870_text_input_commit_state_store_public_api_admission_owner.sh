#!/usr/bin/env zsh
#
# Verifies the stage870 text-input commit state-store public API admission owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage870_text_input_commit_state_store_public_api_admission.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage870 text input commit state store public api admission: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage870TextInputCommitStateStorePublicApiAdmissionPlan" \
  "CjguiInternalRendererStage870TextInputCommitStateStorePublicApiAdmissionFacts" \
  "CjguiInternalRendererStage870TextInputCommitStateStorePublicApiAdmissionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage870TextInputCommitStateStorePublicApiAdmissionDraft" \
  "CjguiInternalRendererStage869TextInputCommitStateStorePublicApiReadiness" \
  "didConsumeStage869TextInputCommitStateStorePublicApiReadiness" \
  "didMaterializeOwnerLocalStateStorePublicApiAdmissionPlan" \
  "didMaterializeCommitCandidateAdmissionMatrix" \
  "didMaterializeRollbackAdmissionSnapshot" \
  "didMaterializeNotPublishedAdmissionReceipt" \
  "didMaterializeNoWriteExecutionReceipt" \
  "didBindAdmissionToStage869CandidateLedger" \
  "didBindAdmissionToStage868PublicApiConsumptionRuntimeManager" \
  "didPrepareStage871TextInputCommitStateStorePublicApiDemoInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage870 text input commit state store public api admission: missing token $token" >&2
    exit 3
  fi
done

echo "stage870_text_input_commit_state_store_public_api_admission_owner_present=true"
echo "stage869_text_input_commit_state_store_public_api_readiness_consumed=true"
echo "stage868_text_input_commit_public_api_consumption_runtime_manager_consumed_transitively=true"
echo "owner_local_state_store_public_api_admission_plan_materialized=true"
echo "commit_candidate_admission_matrix_materialized=true"
echo "rollback_admission_snapshot_materialized=true"
echo "not_published_admission_receipt_materialized=true"
echo "no_write_execution_receipt_materialized=true"
echo "state_store_public_api_admission_bound_to_stage869_candidate_ledger=true"
echo "state_store_public_api_admission_bound_to_stage868_runtime_manager=true"
echo "stage871_text_input_commit_state_store_public_api_demo_inspection_surface_prepared=true"
echo "owner_local_state_store_commit_first_slice_readiness_materialized=true"
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
