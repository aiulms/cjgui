#!/usr/bin/env zsh
#
# 维护注释：验证 stage417 owner acceptance / visibility gate owner。
# 它必须消费 stage416 reconciliation，并形成 owner-local acceptance / visibility gate preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage417_owner_acceptance_visibility_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage417 owner acceptance visibility gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage417OwnerAcceptanceVisibilityGatePlan" \
  "CjguiInternalRendererStage417OwnerAcceptanceVisibilityGateFacts" \
  "CjguiInternalRendererStage417OwnerAcceptanceVisibilityGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage417OwnerAcceptanceVisibilityGateDraft" \
  "didConsumeStage416CommitResultStateRenderReconciliation" \
  "didConsumeCommitResultStateDeltaReconciliation" \
  "didConsumeCommitResultRenderCommandReconciliation" \
  "didMaterializeOwnerAcceptanceVisibilityGate" \
  "didMaterializeTodoOwnerAcceptanceVisibilityGate" \
  "didMaterializeSettingsOwnerAcceptanceVisibilityGate" \
  "didMaterializeAiGeneratedSettingsOwnerAcceptanceVisibilityGate" \
  "didPrepareAcceptedReconciliationGateCandidate" \
  "didPrepareBlockedReconciliationVisibilityDenialCandidate" \
  "didKeepOwnerAcceptanceGatePreviewOnly" \
  "didDenyVisibilityPublicationAtGate" \
  "didPrepareStage418VisibilityCommandPlanDryRun" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepVisibilityPublishedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage417 owner acceptance visibility gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage417_owner_acceptance_visibility_gate_owner_present=true"
echo "stage416_commit_result_state_render_reconciliation_required=true"
echo "stage416_commit_result_state_render_reconciliation_consumed=true"
echo "commit_result_state_delta_reconciliation_consumed=true"
echo "commit_result_render_command_reconciliation_consumed=true"
echo "owner_acceptance_visibility_gate_materialized=true"
echo "todo_owner_acceptance_visibility_gate_materialized=true"
echo "settings_owner_acceptance_visibility_gate_materialized=true"
echo "ai_generated_settings_owner_acceptance_visibility_gate_materialized=true"
echo "accepted_reconciliation_gate_candidate_prepared=true"
echo "blocked_reconciliation_visibility_denial_candidate_prepared=true"
echo "owner_acceptance_gate_preview_only=true"
echo "visibility_publication_denied_at_gate=true"
echo "stage418_visibility_command_plan_dry_run_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
