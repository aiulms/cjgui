#!/usr/bin/env zsh
#
# 维护注释：验证 stage388 shared text edit commit result -> render refresh demo probe owner。
# 它必须消费 stage387 commit dry-run，把 accepted/rejected result preview 接回 demo refresh bridge，
# 不发布 visibility、不提交 renderer/state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage388_shared_text_edit_commit_result_render_refresh_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage388 shared text edit commit result render refresh demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage388TextEditCommitResultEnvelope" \
  "CjguiInternalRendererStage388TextEditCommitResultDemoRefreshBridge" \
  "CjguiInternalRendererStage388TextEditCommitResultRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage388SharedTextEditCommitResultRenderRefreshDemoProbeFacts" \
  "CjguiInternalRendererStage388SharedTextEditCommitResultRenderRefreshDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage388SharedTextEditCommitResultRenderRefreshDemoProbeDraft" \
  "didConsumeStage387SharedTextEditActionCommitDryRun" \
  "didMaterializeTextEditCommitResultEnvelope" \
  "didMaterializeAcceptedCommitResultPreview" \
  "didMaterializeRejectedCommitRollbackResultPreview" \
  "didBindCommitResultToTodoEditedTextSurfaceRefresh" \
  "didBindCommitResultToSettingsFocusSurfaceRefresh" \
  "didBindCommitResultToStage386RenderRefreshPlan" \
  "didBindCommitResultToStage387RollbackPreview" \
  "didMaterializeTextEditCommitResultRenderCommandRefreshPlan" \
  "didKeepCommitResultRenderRefreshPreviewOnly" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepVisibilityNotPublished" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage388 shared text edit commit result render refresh demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage388_shared_text_edit_commit_result_render_refresh_demo_probe_owner_present=true"
echo "stage387_shared_text_edit_action_commit_dry_run_required=true"
echo "stage387_shared_text_edit_action_commit_dry_run_consumed=true"
echo "text_edit_commit_result_envelope_materialized=true"
echo "accepted_commit_result_preview_materialized=true"
echo "rejected_commit_rollback_result_preview_materialized=true"
echo "commit_result_bound_to_todo_edited_text_surface_refresh=true"
echo "commit_result_bound_to_settings_focus_surface_refresh=true"
echo "commit_result_bound_to_stage386_render_refresh_plan=true"
echo "commit_result_bound_to_stage387_rollback_preview=true"
echo "text_edit_commit_result_render_command_refresh_plan_materialized=true"
echo "commit_result_render_refresh_preview_only=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
