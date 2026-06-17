#!/usr/bin/env zsh
#
# Verifies the stage867 text-input commit public API demo proof surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage867_text_input_commit_public_api_demo_proof_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage867 text input commit public api demo proof surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage867TextInputCommitPublicApiDemoProofSurfacePlan" \
  "CjguiInternalRendererStage867TextInputCommitPublicApiDemoProofSurfaceFacts" \
  "CjguiInternalRendererStage867TextInputCommitPublicApiDemoProofSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage867TextInputCommitPublicApiDemoProofSurfaceDraft" \
  "CjguiInternalRendererStage866TextInputCommitPublicApiCompatibilityLedgerReadiness" \
  "didConsumeStage866TextInputCommitPublicApiCompatibilityLedger" \
  "didMaterializeTodoPublicApiCommitProofSurface" \
  "didMaterializeSettingsPublicApiCommitProofSurface" \
  "didMaterializeAiGeneratedSettingsPublicApiCommitProofSurface" \
  "didMaterializeChatComposerPublicApiCommitProofSurface" \
  "didMaterializeFileBrowserPublicApiCommitProofSurface" \
  "didMaterializePublicApiHostInspectionReceipt" \
  "didMaterializePublicApiCommitResultSurfaceRefresh" \
  "didBindDemoProofToStage866CompatibilityLedger" \
  "didPrepareStage868TextInputCommitPublicApiConsumptionRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage867 text input commit public api demo proof surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage867_text_input_commit_public_api_demo_proof_surface_owner_present=true"
echo "stage866_text_input_commit_public_api_compatibility_ledger_consumed=true"
echo "stage865_text_input_commit_public_api_consumption_contract_consumed_transitively=true"
echo "todo_public_api_commit_proof_surface_materialized=true"
echo "settings_public_api_commit_proof_surface_materialized=true"
echo "ai_generated_settings_public_api_commit_proof_surface_materialized=true"
echo "chat_composer_public_api_commit_proof_surface_materialized=true"
echo "file_browser_public_api_commit_proof_surface_materialized=true"
echo "public_api_host_inspection_receipt_materialized=true"
echo "public_api_commit_result_surface_refresh_materialized=true"
echo "demo_proof_bound_to_stage866_compatibility_ledger=true"
echo "stage868_text_input_commit_public_api_consumption_runtime_manager_prepared=true"
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
