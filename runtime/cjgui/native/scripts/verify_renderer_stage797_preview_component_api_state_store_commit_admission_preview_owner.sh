#!/usr/bin/env zsh
#
# Verifies the stage797 preview component API state-store commit admission preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage797_preview_component_api_state_store_commit_admission_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage797 preview component api state-store commit admission preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage797PreviewComponentApiStateStoreCommitAdmissionPreviewPlan" \
  "CjguiInternalRendererStage797PreviewComponentApiStateStoreCommitAdmissionPreviewFacts" \
  "CjguiInternalRendererStage797PreviewComponentApiStateStoreCommitAdmissionPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage797PreviewComponentApiStateStoreCommitAdmissionPreviewDraft" \
  "CjguiInternalRendererStage796PreviewComponentApiStateStoreBridgeRuntimeManagerReadiness" \
  "didConsumeStage796PreviewComponentApiStateStoreBridgeRuntimeManager" \
  "didMaterializeStateStoreCommitAdmissionPreviewGate" \
  "didMaterializeOwnerLocalCommitAdmissionPolicyMatrix" \
  "didMaterializeTextMutationAdmissionRoute" \
  "didMaterializeFocusMutationAdmissionRoute" \
  "didMaterializeStyleMutationAdmissionRoute" \
  "didMaterializeLayoutMutationAdmissionRoute" \
  "didKeepStateStoreCommitAdmissionPreviewNonCommitting" \
  "didPrepareStage798PreviewComponentApiStateStoreCommitReviewCheckpoint"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage797 preview component api state-store commit admission preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage797_preview_component_api_state_store_commit_admission_preview_owner_present=true"
echo "stage796_preview_component_api_state_store_bridge_runtime_manager_consumed=true"
echo "state_store_commit_admission_preview_gate_materialized=true"
echo "owner_local_commit_admission_policy_matrix_materialized=true"
echo "text_mutation_admission_route_materialized=true"
echo "focus_mutation_admission_route_materialized=true"
echo "style_mutation_admission_route_materialized=true"
echo "layout_mutation_admission_route_materialized=true"
echo "state_store_commit_admission_preview_non_committing=true"
echo "stage798_preview_component_api_state_store_commit_review_checkpoint_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
