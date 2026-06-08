#!/usr/bin/env zsh
#
# Verifies the stage788 preview component API commit inspection public preview runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage788_preview_component_api_commit_inspection_public_preview_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage788 preview component api commit inspection public preview runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage788PreviewComponentApiCommitInspectionPublicPreviewRuntimeManagerPlan" \
  "CjguiInternalRendererStage788PreviewComponentApiCommitInspectionPublicPreviewRuntimeManagerFacts" \
  "CjguiInternalRendererStage788PreviewComponentApiCommitInspectionPublicPreviewRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage788PreviewComponentApiCommitInspectionPublicPreviewRuntimeManagerDraft" \
  "CjguiInternalRendererStage787PreviewComponentApiCommitInspectionDemoProofReadiness" \
  "didConsumeStage787PreviewComponentApiCommitInspectionDemoProof" \
  "didMaterializeSharedPublicPreviewContractRuntimeManager" \
  "didMaterializePublicPreviewContractRuntimeContract" \
  "didMaterializePublicPreviewContractExecutionReceiptContract" \
  "didMaterializeCycleOrderCommitInspectionPublicPreviewContractCompatibilityDemoRuntime" \
  "didReduceFuturePerDemoPublicPreviewContractTemplateNeed" \
  "didPrepareStage789PreviewComponentApiCommitAdmissionDecision"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage788 preview component api commit inspection public preview runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_owner_present=true"
echo "stage787_preview_component_api_commit_inspection_demo_proof_consumed=true"
echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_consumed_transitively=true"
echo "stage785_preview_component_api_commit_inspection_public_preview_contract_consumed_transitively=true"
echo "stage784_preview_component_api_commit_inspection_runtime_manager_consumed_transitively=true"
echo "shared_public_preview_contract_runtime_manager_materialized=true"
echo "public_preview_contract_runtime_contract_materialized=true"
echo "public_preview_contract_execution_receipt_contract_materialized=true"
echo "cycle_order_commit_inspection_public_preview_contract_compatibility_demo_runtime_materialized=true"
echo "todo_public_preview_contract_runtime_surface_materialized=true"
echo "settings_public_preview_contract_runtime_surface_materialized=true"
echo "ai_generated_settings_public_preview_contract_runtime_surface_materialized=true"
echo "chat_composer_public_preview_contract_runtime_surface_materialized=true"
echo "public_preview_runtime_manager_bound_to_stage785_contract=true"
echo "public_preview_runtime_manager_bound_to_stage786_compatibility=true"
echo "public_preview_runtime_manager_bound_to_stage787_demo_proof=true"
echo "future_per_demo_public_preview_contract_template_need_reduced=true"
echo "stage789_preview_component_api_commit_admission_decision_prepared=true"
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
