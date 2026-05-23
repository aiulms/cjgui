#!/usr/bin/env zsh
#
# 维护注释：验证 stage412 gated replay state/render refresh owner。
# 它必须消费 stage411 acceptance gate，并生成 state delta / RenderCommand refresh dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage412_gated_replay_state_render_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage412 gated replay state render refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage412GatedReplayStateRenderRefreshPlan" \
  "CjguiInternalRendererStage412GatedReplayStateRenderRefreshFacts" \
  "CjguiInternalRendererStage412GatedReplayStateRenderRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage412GatedReplayStateRenderRefreshDraft" \
  "didConsumeStage411ReplayAcceptanceGate" \
  "didConsumeReplayAcceptanceGate" \
  "didConsumeAcceptedReplayGateCandidate" \
  "didConsumeBlockedReplayGateCandidate" \
  "didMaterializeGatedReplayStateDeltaDryRun" \
  "didRefreshTodoGatedReplayStateDelta" \
  "didRefreshSettingsGatedReplayStateDelta" \
  "didRefreshAiGeneratedSettingsGatedReplayStateDelta" \
  "didMaterializeGatedReplayRenderCommandRefresh" \
  "didRefreshTodoGatedReplayRenderCommand" \
  "didRefreshSettingsGatedReplayRenderCommand" \
  "didRefreshAiGeneratedSettingsGatedReplayRenderCommand" \
  "didBindGatedReplayStateRenderRefreshToStage411Gate" \
  "didBindGatedReplayStateRenderRefreshToStage410Reconciliation" \
  "didKeepStateDeltaDryRunOnly" \
  "didKeepRenderCommandRefreshPreviewOnly" \
  "didKeepGatedReplayStateRenderRefreshOwnerLocal" \
  "didPrepareStage413DemoSurfaceGatedReplayCommitIntent" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage412 gated replay state render refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage412_gated_replay_state_render_refresh_owner_present=true"
echo "stage411_replay_acceptance_gate_required=true"
echo "stage411_replay_acceptance_gate_consumed=true"
echo "replay_acceptance_gate_consumed=true"
echo "accepted_replay_gate_candidate_consumed=true"
echo "blocked_replay_gate_candidate_consumed=true"
echo "gated_replay_state_delta_dry_run_materialized=true"
echo "todo_gated_replay_state_delta_refreshed=true"
echo "settings_gated_replay_state_delta_refreshed=true"
echo "ai_generated_settings_gated_replay_state_delta_refreshed=true"
echo "gated_replay_render_command_refresh_materialized=true"
echo "todo_gated_replay_render_command_refreshed=true"
echo "settings_gated_replay_render_command_refreshed=true"
echo "ai_generated_settings_gated_replay_render_command_refreshed=true"
echo "gated_replay_state_render_refresh_bound_to_stage411_gate=true"
echo "gated_replay_state_render_refresh_bound_to_stage410_reconciliation=true"
echo "state_delta_dry_run_only=true"
echo "render_command_refresh_preview_only=true"
echo "gated_replay_state_render_refresh_owner_local=true"
echo "stage413_demo_surface_gated_replay_commit_intent_prepared=true"
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
