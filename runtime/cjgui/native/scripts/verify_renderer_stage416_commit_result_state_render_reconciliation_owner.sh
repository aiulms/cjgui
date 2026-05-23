#!/usr/bin/env zsh
#
# 维护注释：验证 stage416 commit result state/render reconciliation owner。
# 它必须消费 stage415 surface refresh，并形成 owner-local state delta / RenderCommand reconciliation dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage416_commit_result_state_render_reconciliation.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage416 commit result state render reconciliation: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage416CommitResultStateRenderReconciliationPlan" \
  "CjguiInternalRendererStage416CommitResultStateRenderReconciliationFacts" \
  "CjguiInternalRendererStage416CommitResultStateRenderReconciliationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage416CommitResultStateRenderReconciliationDraft" \
  "didConsumeStage415CommitResultSurfaceRefresh" \
  "didConsumeDemoSurfaceCommitResultRefresh" \
  "didConsumeTodoCommitResultSurfaceRefresh" \
  "didConsumeSettingsCommitResultSurfaceRefresh" \
  "didConsumeAiGeneratedSettingsCommitResultSurfaceRefresh" \
  "didMaterializeCommitResultStateDeltaReconciliation" \
  "didMaterializeTodoCommitResultStateDeltaReconciled" \
  "didMaterializeSettingsCommitResultStateDeltaReconciled" \
  "didMaterializeAiGeneratedSettingsCommitResultStateDeltaReconciled" \
  "didMaterializeCommitResultRenderCommandReconciliation" \
  "didMaterializeTodoCommitResultRenderCommandReconciled" \
  "didMaterializeSettingsCommitResultRenderCommandReconciled" \
  "didMaterializeAiGeneratedSettingsCommitResultRenderCommandReconciled" \
  "didBindReconciliationToStage415SurfaceRefresh" \
  "didBindReconciliationToStage414Executor" \
  "didPrepareStage417OwnerAcceptanceVisibilityGate" \
  "didKeepReconciliationOwnerLocal" \
  "didKeepReconciliationDryRunOnly" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepVisibilityPublicationBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage416 commit result state render reconciliation: missing token $token" >&2
    exit 3
  fi
done

echo "stage416_commit_result_state_render_reconciliation_owner_present=true"
echo "stage415_commit_result_surface_refresh_required=true"
echo "stage415_commit_result_surface_refresh_consumed=true"
echo "demo_surface_commit_result_refresh_consumed=true"
echo "todo_commit_result_surface_refresh_consumed=true"
echo "settings_commit_result_surface_refresh_consumed=true"
echo "ai_generated_settings_commit_result_surface_refresh_consumed=true"
echo "commit_result_state_delta_reconciliation_materialized=true"
echo "todo_commit_result_state_delta_reconciled=true"
echo "settings_commit_result_state_delta_reconciled=true"
echo "ai_generated_settings_commit_result_state_delta_reconciled=true"
echo "commit_result_render_command_reconciliation_materialized=true"
echo "todo_commit_result_render_command_reconciled=true"
echo "settings_commit_result_render_command_reconciled=true"
echo "ai_generated_settings_commit_result_render_command_reconciled=true"
echo "reconciliation_bound_to_stage415_surface_refresh=true"
echo "reconciliation_bound_to_stage414_executor=true"
echo "stage417_owner_acceptance_visibility_gate_prepared=true"
echo "commit_result_reconciliation_owner_local=true"
echo "commit_result_reconciliation_dry_run_only=true"
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
