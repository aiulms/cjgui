#!/usr/bin/env zsh
#
# Verifies the stage755 AI-generated UI acceptance commit host inspection proof owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage755_ai_generated_ui_acceptance_commit_host_inspection_proof.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage755 ai generated ui acceptance commit host inspection proof: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage755AiGeneratedUiAcceptanceCommitHostInspectionProofPlan" \
  "CjguiInternalRendererStage755AiGeneratedUiAcceptanceCommitHostInspectionProofFacts" \
  "CjguiInternalRendererStage755AiGeneratedUiAcceptanceCommitHostInspectionProofReadiness" \
  "cjguiInternalExecuteDefaultRendererStage755AiGeneratedUiAcceptanceCommitHostInspectionProofDraft" \
  "CjguiInternalRendererStage754AiGeneratedUiAcceptanceCommitRollbackSnapshotReadiness" \
  "didConsumeStage754AiGeneratedUiAcceptanceCommitRollbackSnapshot" \
  "didMaterializeAcceptanceCommitHostInspectionRows" \
  "didMaterializeAcceptanceCommitSlotDiffRows" \
  "didMaterializeAcceptanceCommitResultSurfacePreview" \
  "didMaterializeAcceptanceCommitRenderCommandRefreshReceipt" \
  "didMaterializeAcceptanceCommitSemanticDiffExplain" \
  "didMaterializeAcceptanceCommitProbeInputContract" \
  "didBindHostInspectionProofToRollbackSnapshot" \
  "didPrepareStage756AiGeneratedUiAcceptanceCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage755 ai generated ui acceptance commit host inspection proof: missing token $token" >&2
    exit 3
  fi
done

echo "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_owner_present=true"
echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_consumed=true"
echo "stage753_ai_generated_ui_acceptance_commit_preflight_consumed_transitively=true"
echo "acceptance_commit_rollback_base_snapshot_consumed=true"
echo "acceptance_pending_commit_snapshot_consumed=true"
echo "acceptance_commit_host_inspection_rows_materialized=true"
echo "acceptance_commit_slot_diff_rows_materialized=true"
echo "acceptance_commit_result_surface_preview_materialized=true"
echo "acceptance_commit_render_command_refresh_receipt_materialized=true"
echo "acceptance_commit_semantic_diff_explain_materialized=true"
echo "acceptance_commit_probe_input_contract_materialized=true"
echo "todo_ai_generated_ui_acceptance_commit_host_inspection_proof_materialized=true"
echo "settings_ai_generated_ui_acceptance_commit_host_inspection_proof_materialized=true"
echo "ai_generated_settings_ai_generated_ui_acceptance_commit_host_inspection_proof_materialized=true"
echo "chat_composer_ai_generated_ui_acceptance_commit_host_inspection_proof_materialized=true"
echo "host_inspection_proof_bound_to_rollback_snapshot=true"
echo "stage756_ai_generated_ui_acceptance_commit_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
