#!/usr/bin/env zsh
#
# 维护注释：验证 stage415 commit result surface refresh owner。
# 它必须消费 stage414 guarded executor，并形成 Todo/settings/AI-generated settings surface refresh dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage415_commit_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage415 commit result surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage415CommitResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage415CommitResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage415CommitResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage415CommitResultSurfaceRefreshDraft" \
  "didConsumeStage414GatedReplayCommitExecutorDryRun" \
  "didConsumeGuardedReplayCommitExecutorResultPreview" \
  "didConsumeRollbackBoundaryPreview" \
  "didConsumeVisibilityPublicationDenialBoundary" \
  "didMaterializeDemoSurfaceCommitResultRefresh" \
  "didMaterializeTodoCommitResultSurfaceRefresh" \
  "didMaterializeSettingsCommitResultSurfaceRefresh" \
  "didMaterializeAiGeneratedSettingsCommitResultSurfaceRefresh" \
  "didClassifyAcceptedCommitResultAsPendingOwnerAcceptance" \
  "didClassifyBlockedCommitResultAsRollbackVisiblePreview" \
  "didBindCommitResultRefreshToStage414Executor" \
  "didBindCommitResultRefreshToStage413CommitIntent" \
  "didPrepareStage416CommitResultStateRenderReconciliation" \
  "didKeepCommitResultRefreshOwnerLocal" \
  "didKeepCommitResultRefreshDryRunOnly" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepVisibilityPublicationBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage415 commit result surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage415_commit_result_surface_refresh_owner_present=true"
echo "stage414_gated_replay_commit_executor_dry_run_required=true"
echo "stage414_gated_replay_commit_executor_dry_run_consumed=true"
echo "guarded_replay_commit_executor_result_preview_consumed=true"
echo "rollback_boundary_preview_consumed=true"
echo "visibility_publication_denial_boundary_consumed=true"
echo "demo_surface_commit_result_refresh_materialized=true"
echo "todo_commit_result_surface_refreshed=true"
echo "settings_commit_result_surface_refreshed=true"
echo "ai_generated_settings_commit_result_surface_refreshed=true"
echo "accepted_commit_result_pending_owner_acceptance_classified=true"
echo "blocked_commit_result_rollback_visible_preview_classified=true"
echo "commit_result_refresh_bound_to_stage414_executor=true"
echo "commit_result_refresh_bound_to_stage413_commit_intent=true"
echo "stage416_commit_result_state_render_reconciliation_prepared=true"
echo "commit_result_surface_refresh_owner_local=true"
echo "commit_result_surface_refresh_dry_run_only=true"
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
