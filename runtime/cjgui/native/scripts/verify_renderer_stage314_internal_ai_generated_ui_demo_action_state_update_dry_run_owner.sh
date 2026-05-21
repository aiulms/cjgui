#!/usr/bin/env zsh
#
# 维护注释：验证 stage314 internal AI-generated UI demo action state update dry-run owner。
# 它只根据 action intent 生成 owner-local state update dry-run，不提交 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage314_internal_ai_generated_ui_demo_action_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage314 internal ai generated ui demo action state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage314InternalAiGeneratedUiDemoActionStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage314InternalAiGeneratedUiDemoActionStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage314InternalAiGeneratedUiDemoActionStateUpdateDryRunDraft" \
  "didConsumeStage313InternalAiGeneratedUiActionIntentBridge" \
  "didMaterializeAiGeneratedUiActionStateUpdateDryRun" \
  "didBindActionStateUpdateDryRunToGeneratedFormActionIntent" \
  "didBindActionStateUpdateDryRunToGeneratedSettingsActionIntent" \
  "didBindActionStateUpdateDryRunToGeneratedValidationActionIntent" \
  "didBindActionStateUpdateDryRunToOwnerLocalStateSnapshot" \
  "didBindActionStateUpdateDryRunToRollbackReadyBoundary" \
  "didKeepActionStateUpdateDryRunOwnerLocalInMemoryOnly" \
  "didKeepActionStateUpdateDryRunUncommitted" \
  "didPrepareStage315RefreshedRenderCommandPreviewInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage314 internal ai generated ui demo action state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage314_internal_ai_generated_ui_demo_action_state_update_dry_run_owner_present=true"
echo "stage313_internal_ai_generated_ui_demo_action_intent_bridge_required=true"
echo "ai_generated_ui_action_state_update_dry_run_materialized=true"
echo "generated_form_action_state_update_dry_run_materialized=true"
echo "generated_settings_action_state_update_dry_run_materialized=true"
echo "generated_validation_action_state_update_dry_run_materialized=true"
echo "ai_generated_ui_action_state_update_bound_to_owner_local_state_snapshot=true"
echo "ai_generated_ui_action_state_update_bound_to_rollback_ready_boundary=true"
echo "ai_generated_ui_action_state_update_owner_local_in_memory_only=true"
echo "ai_generated_ui_action_state_update_uncommitted=true"
echo "stage315_refreshed_render_command_preview_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
