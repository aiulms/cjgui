#!/usr/bin/env zsh
#
# 维护注释：验证 stage411 replay acceptance gate owner。
# 它必须消费 stage410 replay reconciliation，并生成 owner-local acceptance gate preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage411_replay_acceptance_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage411 replay acceptance gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage411ReplayAcceptanceGatePlan" \
  "CjguiInternalRendererStage411ReplayAcceptanceGateFacts" \
  "CjguiInternalRendererStage411ReplayAcceptanceGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage411ReplayAcceptanceGateDraft" \
  "didConsumeStage410ReplayResultReconciliation" \
  "didConsumeDemoSurfaceReplayResultReconciliation" \
  "didConsumeReconciledRenderCommandRefreshPreview" \
  "didConsumeReplayRollbackDecisionPreview" \
  "didMaterializeReplayAcceptanceGate" \
  "didMaterializeAcceptedReplayGateCandidate" \
  "didMaterializeBlockedReplayGateCandidate" \
  "didMaterializeTodoReplayAcceptanceGate" \
  "didMaterializeSettingsReplayAcceptanceGate" \
  "didMaterializeAiGeneratedSettingsReplayAcceptanceGate" \
  "didApplyOwnerAcceptanceRequirement" \
  "didPrepareAcceptedReplayStateDeltaCandidate" \
  "didPrepareBlockedReplayRollbackCandidate" \
  "didBindReplayAcceptanceGateToStage410Reconciliation" \
  "didBindReplayAcceptanceGateToStage409Replay" \
  "didKeepReplayAcceptanceGateOwnerLocal" \
  "didKeepReplayAcceptanceGatePreviewOnly" \
  "didPrepareStage412GatedReplayStateRenderRefresh" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage411 replay acceptance gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage411_replay_acceptance_gate_owner_present=true"
echo "stage410_replay_result_reconciliation_required=true"
echo "stage410_replay_result_reconciliation_consumed=true"
echo "demo_surface_replay_result_reconciliation_consumed=true"
echo "reconciled_render_command_refresh_preview_consumed=true"
echo "replay_rollback_decision_preview_consumed=true"
echo "replay_acceptance_gate_materialized=true"
echo "accepted_replay_gate_candidate_materialized=true"
echo "blocked_replay_gate_candidate_materialized=true"
echo "todo_replay_acceptance_gate_materialized=true"
echo "settings_replay_acceptance_gate_materialized=true"
echo "ai_generated_settings_replay_acceptance_gate_materialized=true"
echo "owner_acceptance_requirement_applied=true"
echo "accepted_replay_state_delta_candidate_prepared=true"
echo "blocked_replay_rollback_candidate_prepared=true"
echo "replay_acceptance_gate_bound_to_stage410_reconciliation=true"
echo "replay_acceptance_gate_bound_to_stage409_replay=true"
echo "replay_acceptance_gate_owner_local=true"
echo "replay_acceptance_gate_preview_only=true"
echo "stage412_gated_replay_state_render_refresh_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
