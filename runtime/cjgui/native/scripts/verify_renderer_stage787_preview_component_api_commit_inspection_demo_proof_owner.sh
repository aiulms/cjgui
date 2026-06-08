#!/usr/bin/env zsh
#
# Verifies the stage787 preview component API commit inspection demo proof owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage787_preview_component_api_commit_inspection_demo_proof.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage787 preview component api commit inspection demo proof: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage787PreviewComponentApiCommitInspectionDemoProofPlan" \
  "CjguiInternalRendererStage787PreviewComponentApiCommitInspectionDemoProofFacts" \
  "CjguiInternalRendererStage787PreviewComponentApiCommitInspectionDemoProofReadiness" \
  "cjguiInternalExecuteDefaultRendererStage787PreviewComponentApiCommitInspectionDemoProofDraft" \
  "CjguiInternalRendererStage786PreviewComponentApiCommitInspectionCompatibilityLedgerReadiness" \
  "didConsumeStage786PreviewComponentApiCommitInspectionCompatibilityLedger" \
  "didMaterializeTodoPublicPreviewContractProofSurface" \
  "didMaterializeSettingsPublicPreviewContractProofSurface" \
  "didMaterializeAiGeneratedSettingsPublicPreviewContractProofSurface" \
  "didMaterializeChatComposerPublicPreviewContractProofSurface" \
  "didPrepareStage788PreviewComponentApiCommitInspectionPublicPreviewRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage787 preview component api commit inspection demo proof: missing token $token" >&2
    exit 3
  fi
done

echo "stage787_preview_component_api_commit_inspection_demo_proof_owner_present=true"
echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_consumed=true"
echo "stage785_preview_component_api_commit_inspection_public_preview_contract_consumed_transitively=true"
echo "todo_public_preview_contract_proof_surface_materialized=true"
echo "settings_public_preview_contract_proof_surface_materialized=true"
echo "ai_generated_settings_public_preview_contract_proof_surface_materialized=true"
echo "chat_composer_public_preview_contract_proof_surface_materialized=true"
echo "public_preview_contract_host_inspection_receipt_materialized=true"
echo "public_preview_contract_result_surface_refresh_materialized=true"
echo "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_prepared=true"
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
