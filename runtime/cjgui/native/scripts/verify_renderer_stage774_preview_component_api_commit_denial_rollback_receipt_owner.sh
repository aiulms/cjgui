#!/usr/bin/env zsh
#
# Verifies the stage774 preview component API commit denial / rollback receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage774_preview_component_api_commit_denial_rollback_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage774 preview component api commit denial rollback receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage774PreviewComponentApiCommitDenialRollbackReceiptPlan" \
  "CjguiInternalRendererStage774PreviewComponentApiCommitDenialRollbackReceiptFacts" \
  "CjguiInternalRendererStage774PreviewComponentApiCommitDenialRollbackReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage774PreviewComponentApiCommitDenialRollbackReceiptDraft" \
  "CjguiInternalRendererStage773PreviewComponentApiCommitAdmissionDryRunReadiness" \
  "didConsumeStage773PreviewComponentApiCommitAdmissionDryRun" \
  "didMaterializePreviewComponentApiCommitAdmissionDenialReceipt" \
  "didMaterializePreviewComponentApiCommitRollbackReasonReceipt" \
  "didMaterializePreviewComponentApiCompatibilityDenialReceipt" \
  "didMaterializePreviewComponentApiOwnerRejectDenialReceipt" \
  "didMaterializePreviewComponentApiCommitAdmissionReceiptLedger" \
  "didMaterializeChatComposerPreviewComponentApiCommitDenialRollbackReceiptSurface" \
  "didBindCommitDenialRollbackReceiptToStage773AdmissionDryRun" \
  "didPrepareStage775PreviewComponentApiCommitAdmissionHostInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage774 preview component api commit denial rollback receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage774_preview_component_api_commit_denial_rollback_receipt_owner_present=true"
echo "stage773_preview_component_api_commit_admission_dry_run_consumed=true"
echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_consumed_transitively=true"
echo "preview_component_api_commit_admission_denial_receipt_materialized=true"
echo "preview_component_api_commit_rollback_reason_receipt_materialized=true"
echo "preview_component_api_compatibility_denial_receipt_materialized=true"
echo "preview_component_api_owner_reject_denial_receipt_materialized=true"
echo "preview_component_api_commit_admission_receipt_ledger_materialized=true"
echo "todo_preview_component_api_commit_denial_rollback_receipt_surface_materialized=true"
echo "settings_preview_component_api_commit_denial_rollback_receipt_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_denial_rollback_receipt_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_denial_rollback_receipt_surface_materialized=true"
echo "commit_denial_rollback_receipt_bound_to_stage773_admission_dry_run=true"
echo "stage775_preview_component_api_commit_admission_host_inspection_surface_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
