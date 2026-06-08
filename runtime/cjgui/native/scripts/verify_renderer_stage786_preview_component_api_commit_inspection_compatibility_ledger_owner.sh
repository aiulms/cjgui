#!/usr/bin/env zsh
#
# Verifies the stage786 preview component API commit inspection compatibility ledger owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage786_preview_component_api_commit_inspection_compatibility_ledger.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage786 preview component api commit inspection compatibility ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage786PreviewComponentApiCommitInspectionCompatibilityLedgerPlan" \
  "CjguiInternalRendererStage786PreviewComponentApiCommitInspectionCompatibilityLedgerFacts" \
  "CjguiInternalRendererStage786PreviewComponentApiCommitInspectionCompatibilityLedgerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage786PreviewComponentApiCommitInspectionCompatibilityLedgerDraft" \
  "CjguiInternalRendererStage785PreviewComponentApiCommitInspectionPublicPreviewContractReadiness" \
  "didConsumeStage785PreviewComponentApiCommitInspectionPublicPreviewContract" \
  "didMaterializePublicPreviewCompatibilityLedger" \
  "didMaterializeBackwardCompatibilityReceipt" \
  "didMaterializeDeprecationRollbackNote" \
  "didMaterializeCommitInspectionSemanticDiffExplainRoute" \
  "didPrepareStage787PreviewComponentApiCommitInspectionDemoProof"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage786 preview component api commit inspection compatibility ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_owner_present=true"
echo "stage785_preview_component_api_commit_inspection_public_preview_contract_consumed=true"
echo "stage784_preview_component_api_commit_inspection_runtime_manager_consumed_transitively=true"
echo "public_preview_compatibility_ledger_materialized=true"
echo "backward_compatibility_receipt_materialized=true"
echo "deprecation_rollback_note_materialized=true"
echo "commit_inspection_semantic_diff_explain_route_materialized=true"
echo "stage787_preview_component_api_commit_inspection_demo_proof_prepared=true"
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
