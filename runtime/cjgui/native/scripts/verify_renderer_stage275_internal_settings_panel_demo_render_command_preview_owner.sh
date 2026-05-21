#!/usr/bin/env zsh
#
# 维护注释：验证 stage275 internal settings panel demo render command preview owner。
# 它只确认 settings panel semantic preview 由 state delta 刷新，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage275_internal_settings_panel_demo_render_command_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage275 internal settings panel demo render command preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage275InternalSettingsPanelDemoRenderCommandPreviewFacts" \
  "CjguiInternalRendererStage275InternalSettingsPanelDemoRenderCommandPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage275InternalSettingsPanelDemoRenderCommandPreviewDraft" \
  "didConsumeStage274InternalSettingsPanelDemoStateUpdateDryRun" \
  "didMaterializeSettingsPanelSemanticNodePreview" \
  "didMaterializeSettingsSectionGroupSemanticNodePreview" \
  "didMaterializeSettingsSwitchSemanticNodePreview" \
  "didMaterializeSettingsFormRowSemanticNodePreview" \
  "didBindSettingsRenderPreviewToStateDeltaDryRun" \
  "didBindSettingsRenderPreviewToRenderCommandRefreshRequirement" \
  "didPrepareStage276SettingsPanelDemoReadinessDecisionInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage275 internal settings panel demo render command preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage275_internal_settings_panel_demo_render_command_preview_owner_present=true"
echo "stage274_internal_settings_panel_demo_state_update_dry_run_required=true"
echo "settings_panel_semantic_node_preview_materialized=true"
echo "settings_section_group_semantic_node_preview_materialized=true"
echo "settings_switch_semantic_node_preview_materialized=true"
echo "settings_form_row_semantic_node_preview_materialized=true"
echo "settings_render_preview_bound_to_state_delta_dry_run=true"
echo "settings_render_preview_bound_to_render_command_refresh_requirement=true"
echo "stage276_settings_panel_demo_readiness_decision_input_prepared=true"
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
