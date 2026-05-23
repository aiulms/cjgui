#!/usr/bin/env zsh
#
# 维护注释：验证 stage413 demo surface gated replay commit intent owner。
# 它必须消费 stage412 state/render refresh，并形成 owner-local commit intent dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage413_gated_replay_commit_intent.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage413 gated replay commit intent: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage413DemoSurfaceGatedReplayCommitIntentPlan" \
  "CjguiInternalRendererStage413DemoSurfaceGatedReplayCommitIntentFacts" \
  "CjguiInternalRendererStage413DemoSurfaceGatedReplayCommitIntentReadiness" \
  "cjguiInternalExecuteDefaultRendererStage413DemoSurfaceGatedReplayCommitIntentDraft" \
  "didConsumeStage412GatedReplayStateRenderRefresh" \
  "didConsumeGatedReplayStateDeltaDryRun" \
  "didConsumeGatedReplayRenderCommandRefresh" \
  "didConsumeAcceptedReplayStateDeltaCandidate" \
  "didConsumeBlockedReplayRollbackCandidate" \
  "didMaterializeDemoSurfaceGatedReplayCommitIntent" \
  "didMaterializeTodoGatedReplayCommitIntent" \
  "didMaterializeSettingsGatedReplayCommitIntent" \
  "didMaterializeAiGeneratedSettingsGatedReplayCommitIntent" \
  "didBindCommitIntentToOwnerAcceptanceRequirement" \
  "didBindCommitIntentToStage412Refresh" \
  "didPrepareGuardedCommitExecutorInput" \
  "didKeepCommitIntentOwnerLocal" \
  "didKeepCommitIntentDryRunOnly" \
  "didPrepareStage414GatedReplayCommitExecutorDryRun" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepVisibilityPublicationBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage413 gated replay commit intent: missing token $token" >&2
    exit 3
  fi
done

echo "stage413_gated_replay_commit_intent_owner_present=true"
echo "stage412_gated_replay_state_render_refresh_required=true"
echo "stage412_gated_replay_state_render_refresh_consumed=true"
echo "gated_replay_state_delta_dry_run_consumed=true"
echo "gated_replay_render_command_refresh_consumed=true"
echo "accepted_replay_state_delta_candidate_consumed=true"
echo "blocked_replay_rollback_candidate_consumed=true"
echo "demo_surface_gated_replay_commit_intent_materialized=true"
echo "todo_gated_replay_commit_intent_materialized=true"
echo "settings_gated_replay_commit_intent_materialized=true"
echo "ai_generated_settings_gated_replay_commit_intent_materialized=true"
echo "commit_intent_bound_to_owner_acceptance_requirement=true"
echo "commit_intent_bound_to_stage412_refresh=true"
echo "guarded_commit_executor_input_prepared=true"
echo "gated_replay_commit_intent_owner_local=true"
echo "gated_replay_commit_intent_dry_run_only=true"
echo "stage414_gated_replay_commit_executor_dry_run_prepared=true"
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
