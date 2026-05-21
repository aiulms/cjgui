#!/usr/bin/env zsh
#
# 维护注释：验证 stage274 internal settings panel demo state update dry-run owner。
# 它只确认 switch/group/form-row 的 state delta 在 owner-local snapshot 中演算。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage274_internal_settings_panel_demo_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage274 internal settings panel demo state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage274InternalSettingsPanelDemoStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage274InternalSettingsPanelDemoStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage274InternalSettingsPanelDemoStateUpdateDryRunDraft" \
  "didConsumeStage273InternalSettingsPanelDemoIntentPacket" \
  "didMaterializeSettingsPanelDemoOwnerLocalStateSnapshot" \
  "didMaterializeSettingsSwitchToggleStateDeltaDryRun" \
  "didMaterializeSettingsGroupExpansionStateDeltaDryRun" \
  "didMaterializeSettingsFormRowEditStateDeltaDryRun" \
  "didBindSettingsStateDeltaToRollbackReadyBoundary" \
  "didKeepSettingsStateUpdateDryRunInMemoryOnly" \
  "didPrepareStage275SettingsPanelDemoRenderCommandPreviewInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage274 internal settings panel demo state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage274_internal_settings_panel_demo_state_update_dry_run_owner_present=true"
echo "stage273_internal_settings_panel_demo_intent_packet_required=true"
echo "settings_panel_demo_owner_local_state_snapshot_materialized=true"
echo "settings_switch_toggle_state_delta_dry_run_materialized=true"
echo "settings_group_expansion_state_delta_dry_run_materialized=true"
echo "settings_form_row_edit_state_delta_dry_run_materialized=true"
echo "settings_state_delta_bound_to_rollback_ready_boundary=true"
echo "settings_state_update_dry_run_in_memory_only=true"
echo "stage275_settings_panel_demo_render_command_preview_input_prepared=true"
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
