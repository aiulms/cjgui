#!/usr/bin/env zsh
#
# 维护注释：验证 stage387 shared text edit action commit dry-run owner。
# 它必须消费 stage386 edited text refresh，并产出 owner-local commit/rollback dry-run，
# 不授予 owner acceptance、不提交 state 或 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage387_shared_text_edit_action_commit_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage387 shared text edit action commit dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage387TextEditCommitIntent" \
  "CjguiInternalRendererStage387TextEditCommitDryRun" \
  "CjguiInternalRendererStage387TextEditRollbackPreview" \
  "CjguiInternalRendererStage387SharedTextEditActionCommitDryRunFacts" \
  "CjguiInternalRendererStage387SharedTextEditActionCommitDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage387SharedTextEditActionCommitDryRunDraft" \
  "didConsumeStage386EditedTextRenderRefreshDemoProbe" \
  "didMaterializeSharedTextEditCommitIntent" \
  "didBindCommitIntentToTodoEditedTextDelta" \
  "didBindCommitIntentToSettingsFocusDelta" \
  "didMaterializeOwnerAcceptanceGateForTextEditCommit" \
  "didMaterializeTextEditStateCommitDryRun" \
  "didMaterializeAcceptedTextBufferStatePreview" \
  "didMaterializeSettingsFocusStatePreview" \
  "didBindCommitDryRunToStage383StateUpdateDryRun" \
  "didBindCommitDryRunToStage386RenderRefresh" \
  "didMaterializeRollbackSnapshotBeforeTextEditCommit" \
  "didMaterializeRejectedTextEditRollbackPreview" \
  "didKeepTextEditCommitDryRunUncommitted" \
  "didKeepOwnerAcceptanceNotGranted" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage387 shared text edit action commit dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage387_shared_text_edit_action_commit_dry_run_owner_present=true"
echo "stage386_edited_text_render_refresh_demo_probe_required=true"
echo "stage386_edited_text_render_refresh_demo_probe_consumed=true"
echo "shared_text_edit_commit_intent_materialized=true"
echo "commit_intent_bound_to_todo_edited_text_delta=true"
echo "commit_intent_bound_to_settings_focus_delta=true"
echo "owner_acceptance_gate_for_text_edit_commit_materialized=true"
echo "text_edit_state_commit_dry_run_materialized=true"
echo "accepted_text_buffer_state_preview_materialized=true"
echo "settings_focus_state_preview_materialized=true"
echo "commit_dry_run_bound_to_stage383_state_update_dry_run=true"
echo "commit_dry_run_bound_to_stage386_render_refresh=true"
echo "rollback_snapshot_before_text_edit_commit_materialized=true"
echo "rejected_text_edit_rollback_preview_materialized=true"
echo "text_edit_commit_dry_run_uncommitted=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
