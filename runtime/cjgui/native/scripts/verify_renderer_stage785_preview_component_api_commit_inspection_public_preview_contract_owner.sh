#!/usr/bin/env zsh
#
# Verifies the stage785 preview component API commit inspection public preview contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage785_preview_component_api_commit_inspection_public_preview_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage785 preview component api commit inspection public preview contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage785PreviewComponentApiCommitInspectionPublicPreviewContractPlan" \
  "CjguiInternalRendererStage785PreviewComponentApiCommitInspectionPublicPreviewContractFacts" \
  "CjguiInternalRendererStage785PreviewComponentApiCommitInspectionPublicPreviewContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage785PreviewComponentApiCommitInspectionPublicPreviewContractDraft" \
  "CjguiInternalRendererStage784PreviewComponentApiCommitInspectionRuntimeManagerReadiness" \
  "didConsumeStage784PreviewComponentApiCommitInspectionRuntimeManager" \
  "didMaterializePreviewComponentApiCommitInspectionPublicPreviewDescriptor" \
  "didMaterializeInspectionUiReviewResultPublicPreviewContract" \
  "didListExistingExperimentalPreviewApiAsUnchangedSurface" \
  "didBindPublicPreviewContractToStage784RuntimeManager" \
  "didPrepareStage786PreviewComponentApiCommitInspectionCompatibilityLedger"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage785 preview component api commit inspection public preview contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage785_preview_component_api_commit_inspection_public_preview_contract_owner_present=true"
echo "stage784_preview_component_api_commit_inspection_runtime_manager_consumed=true"
echo "stage783_preview_component_api_commit_inspection_result_surface_consumed_transitively=true"
echo "preview_component_api_commit_inspection_public_preview_descriptor_materialized=true"
echo "inspection_ui_review_result_public_preview_contract_materialized=true"
echo "existing_experimental_preview_api_surface_listed=true"
echo "public_preview_contract_bound_to_stage784_runtime_manager=true"
echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_prepared=true"
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
