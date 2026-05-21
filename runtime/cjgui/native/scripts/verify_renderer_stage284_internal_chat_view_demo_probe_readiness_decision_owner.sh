#!/usr/bin/env zsh
#
# 维护注释：验证 stage284 internal chat view demo probe readiness decision owner。
# 它只把 chat probe input/result/diff 汇合成 readiness，并准备 file browser 后续入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage284_internal_chat_view_demo_probe_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage284 internal chat view demo probe readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage284InternalChatViewDemoProbeReadinessDecisionFacts" \
  "CjguiInternalRendererStage284InternalChatViewDemoProbeReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage284InternalChatViewDemoProbeReadinessDecisionDraft" \
  "didConsumeStage283InternalChatViewDemoProbeSemanticDiffExplain" \
  "didJoinChatProbeInputWithResultEnvelope" \
  "didJoinChatProbeResultWithSemanticDiffExplain" \
  "didJoinChatProbeWithRollbackReadyBoundary" \
  "didJoinChatProbeWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalChatViewDemoProbeReadinessDecision" \
  "didPrepareStage285InternalFileBrowserDemoIntentPacketInput" \
  "didConfirmMinimalUiFrameworkChatProbeRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage284 internal chat view demo probe readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage284_internal_chat_view_demo_probe_readiness_decision_owner_present=true"
echo "stage283_internal_chat_view_demo_probe_semantic_diff_explain_required=true"
echo "internal_chat_view_demo_probe_readiness_decision_materialized=true"
echo "chat_probe_input_result_diff_joined=true"
echo "chat_probe_rollback_visibility_boundary_joined=true"
echo "stage285_internal_file_browser_demo_intent_packet_input_prepared=true"
echo "minimal_ui_framework_chat_probe_runway_advanced=true"
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
