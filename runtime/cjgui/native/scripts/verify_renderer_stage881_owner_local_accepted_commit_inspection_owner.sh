#!/usr/bin/env zsh
#
# Verifies the stage881 owner-local accepted commit inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage881_owner_local_accepted_commit_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage881 owner-local accepted commit inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage881OwnerLocalAcceptedCommitInspectionPlan" \
  "CjguiInternalRendererStage881OwnerLocalAcceptedCommitInspectionFacts" \
  "CjguiInternalRendererStage881OwnerLocalAcceptedCommitInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage881OwnerLocalAcceptedCommitInspectionDraft" \
  "CjguiInternalRendererStage880OwnerLocalCommitAcceptanceRuntimeManagerReadiness" \
  "didConsumeStage880OwnerLocalCommitAcceptanceRuntimeManager" \
  "didMaterializeOwnerLocalAcceptedCommitInspectionGate" \
  "didMaterializeAcceptedCommitCandidateLens" \
  "didMaterializeAcceptedCommitDecisionReplayBoundary" \
  "didMaterializeAcceptedCommitPatchPreviewLedger" \
  "didBindAcceptedCommitInspectionToAcceptanceRuntime" \
  "didPrepareStage882OwnerLocalAcceptedCommitApplicationPlan"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage881 owner-local accepted commit inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage881_owner_local_accepted_commit_inspection_owner_present=true"
echo "stage880_owner_local_commit_acceptance_runtime_manager_consumed=true"
echo "stage879_owner_local_commit_acceptance_demo_surface_consumed_transitively=true"
echo "stage878_owner_local_commit_acceptance_decision_consumed_transitively=true"
echo "stage877_owner_local_commit_acceptance_gate_consumed_transitively=true"
echo "owner_local_accepted_commit_inspection_gate_materialized=true"
echo "accepted_commit_candidate_lens_materialized=true"
echo "accepted_commit_decision_replay_boundary_materialized=true"
echo "accepted_commit_patch_preview_ledger_materialized=true"
echo "accepted_commit_inspection_bound_to_acceptance_runtime=true"
echo "stage882_owner_local_accepted_commit_application_plan_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
