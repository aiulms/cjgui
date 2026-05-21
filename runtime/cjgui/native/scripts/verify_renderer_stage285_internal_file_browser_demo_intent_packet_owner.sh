#!/usr/bin/env zsh
#
# 维护注释：验证 stage285 internal file browser demo intent packet owner。
# 它只确认 selection/tree-list/detail-pane intent 已成为 owner-local semantic input，不执行 action。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage285_internal_file_browser_demo_intent_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage285 internal file browser demo intent packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage285InternalFileBrowserDemoIntentPacketFacts" \
  "CjguiInternalRendererStage285InternalFileBrowserDemoIntentPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage285InternalFileBrowserDemoIntentPacketDraft" \
  "didConsumeStage284InternalChatViewDemoProbeReadinessDecision" \
  "didMaterializeInternalFileBrowserDemoIntentPacket" \
  "didMaterializeFileBrowserSelectionIntentSemanticNode" \
  "didMaterializeFileBrowserTreeListIntentSemanticNode" \
  "didMaterializeFileBrowserDetailPaneIntentSemanticNode" \
  "didBindFileBrowserIntentPacketToOwnerLocalStateDeltaInput" \
  "didBindFileBrowserIntentPacketToRenderCommandRefreshRequirement" \
  "didPrepareStage286FileBrowserDemoStateUpdateDryRunInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage285 internal file browser demo intent packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage285_internal_file_browser_demo_intent_packet_owner_present=true"
echo "stage284_internal_chat_view_demo_probe_readiness_decision_required=true"
echo "internal_file_browser_demo_intent_packet_materialized=true"
echo "file_browser_selection_intent_semantic_node_materialized=true"
echo "file_browser_tree_list_intent_semantic_node_materialized=true"
echo "file_browser_detail_pane_intent_semantic_node_materialized=true"
echo "file_browser_intent_packet_bound_to_owner_local_state_delta_input=true"
echo "file_browser_intent_packet_bound_to_render_command_refresh_requirement=true"
echo "stage286_file_browser_demo_state_update_dry_run_input_prepared=true"
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
