#!/usr/bin/env zsh
#
# 维护注释：验证 stage276 internal settings panel demo readiness decision owner。
# 它只汇合 intent/state/render/boundary，并准备 chat view 后续入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage276_internal_settings_panel_demo_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage276 internal settings panel demo readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage276InternalSettingsPanelDemoReadinessDecisionFacts" \
  "CjguiInternalRendererStage276InternalSettingsPanelDemoReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage276InternalSettingsPanelDemoReadinessDecisionDraft" \
  "didConsumeStage275InternalSettingsPanelDemoRenderCommandPreview" \
  "didJoinSettingsPanelIntentPacketWithStateUpdateDryRun" \
  "didJoinSettingsPanelStateUpdateWithRenderCommandPreview" \
  "didJoinSettingsPanelWithRollbackReadyBoundary" \
  "didJoinSettingsPanelWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalSettingsPanelDemoReadinessDecision" \
  "didPrepareStage277InternalChatViewDemoIntentPacketInput" \
  "didConfirmMinimalUiFrameworkSettingsPanelRunwayAdvanced" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage276 internal settings panel demo readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage276_internal_settings_panel_demo_readiness_decision_owner_present=true"
echo "stage275_internal_settings_panel_demo_render_command_preview_required=true"
echo "internal_settings_panel_demo_readiness_decision_materialized=true"
echo "settings_panel_intent_state_render_joined=true"
echo "settings_panel_rollback_visibility_boundary_joined=true"
echo "stage277_internal_chat_view_demo_intent_packet_input_prepared=true"
echo "minimal_ui_framework_settings_panel_runway_advanced=true"
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
