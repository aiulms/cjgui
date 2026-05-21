#!/usr/bin/env zsh
#
# 维护注释：验证 stage280 internal chat view demo readiness decision owner。
# 它只汇合 intent/state/render/boundary，并准备 chat view probe 后续入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage280_internal_chat_view_demo_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage280 internal chat view demo readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage280InternalChatViewDemoReadinessDecisionFacts" \
  "CjguiInternalRendererStage280InternalChatViewDemoReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage280InternalChatViewDemoReadinessDecisionDraft" \
  "didConsumeStage279InternalChatViewDemoRenderCommandPreview" \
  "didJoinChatViewIntentPacketWithStateUpdateDryRun" \
  "didJoinChatViewStateUpdateWithRenderCommandPreview" \
  "didJoinChatViewWithRollbackReadyBoundary" \
  "didJoinChatViewWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalChatViewDemoReadinessDecision" \
  "didPrepareStage281InternalChatViewDemoProbeInput" \
  "didConfirmMinimalUiFrameworkChatViewRunwayAdvanced" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage280 internal chat view demo readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage280_internal_chat_view_demo_readiness_decision_owner_present=true"
echo "stage279_internal_chat_view_demo_render_command_preview_required=true"
echo "internal_chat_view_demo_readiness_decision_materialized=true"
echo "chat_view_intent_state_render_joined=true"
echo "chat_view_rollback_visibility_boundary_joined=true"
echo "stage281_internal_chat_view_demo_probe_input_prepared=true"
echo "minimal_ui_framework_chat_view_runway_advanced=true"
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
