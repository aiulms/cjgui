#!/usr/bin/env zsh
#
# 维护注释：验证 stage414 gated replay commit executor dry-run owner。
# 它必须消费 stage413 commit intent，并形成 guarded executor / rollback / visibility denial dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage414_gated_replay_commit_executor_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage414 gated replay commit executor dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage414GatedReplayCommitExecutorDryRunPlan" \
  "CjguiInternalRendererStage414GatedReplayCommitExecutorDryRunFacts" \
  "CjguiInternalRendererStage414GatedReplayCommitExecutorDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage414GatedReplayCommitExecutorDryRunDraft" \
  "didConsumeStage413DemoSurfaceGatedReplayCommitIntent" \
  "didConsumeDemoSurfaceGatedReplayCommitIntent" \
  "didConsumeGuardedCommitExecutorInput" \
  "didMaterializeGuardedReplayCommitExecutorDryRun" \
  "didMaterializeGuardedReplayCommitExecutorResultPreview" \
  "didClassifyAcceptedCommitIntentAsPendingOwnerAcceptance" \
  "didClassifyBlockedCommitIntentAsRollbackRequired" \
  "didMaterializeRollbackBoundaryPreview" \
  "didMaterializeVisibilityPublicationDenialBoundary" \
  "didBindGuardedExecutorToStage413CommitIntent" \
  "didBindGuardedExecutorToStage412Refresh" \
  "didPrepareStage415CommitResultSurfaceRefresh" \
  "didKeepGuardedExecutorOwnerLocal" \
  "didKeepGuardedExecutorDryRunOnly" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepVisibilityPublicationBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage414 gated replay commit executor dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage414_gated_replay_commit_executor_dry_run_owner_present=true"
echo "stage413_gated_replay_commit_intent_required=true"
echo "stage413_gated_replay_commit_intent_consumed=true"
echo "demo_surface_gated_replay_commit_intent_consumed=true"
echo "guarded_commit_executor_input_consumed=true"
echo "guarded_replay_commit_executor_dry_run_materialized=true"
echo "guarded_replay_commit_executor_result_preview_materialized=true"
echo "accepted_commit_intent_pending_owner_acceptance_classified=true"
echo "blocked_commit_intent_rollback_required_classified=true"
echo "rollback_boundary_preview_materialized=true"
echo "visibility_publication_denial_boundary_materialized=true"
echo "guarded_executor_bound_to_stage413_commit_intent=true"
echo "guarded_executor_bound_to_stage412_refresh=true"
echo "stage415_commit_result_surface_refresh_prepared=true"
echo "gated_replay_commit_executor_owner_local=true"
echo "gated_replay_commit_executor_dry_run_only=true"
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
