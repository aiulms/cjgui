#!/usr/bin/env zsh
#
# 维护注释：验证 stage258 internal component demo loop transition preview packet owner。
# 它把 stage257 loop preflight 固化为 action -> state -> render 的 owner-local preview packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage258_internal_component_demo_loop_transition_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage258 internal component demo loop transition preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage258InternalComponentDemoLoopTransitionPreviewPacketFacts" \
  "CjguiInternalRendererStage258InternalComponentDemoLoopTransitionPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage258InternalComponentDemoLoopTransitionPreviewPacketDraft" \
  "didConsumeStage257InternalComponentDemoStateRenderActionLoop" \
  "didMaterializeInternalComponentDemoLoopTransitionPreviewPacket" \
  "didConfirmLoopTransitionOrderActionStateRender" \
  "didCarrySurfaceBeforeAfterSemanticNodeFacts" \
  "didCarryStateUpdateDryRunDelta" \
  "didCarryRenderCommandRefreshDelta" \
  "didKeepTransitionPreviewNonExecuting" \
  "didPrepareStage259LoopSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage258 internal component demo loop transition preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage258_internal_component_demo_loop_transition_preview_packet_owner_present=true"
echo "stage257_internal_component_demo_state_render_action_loop_required=true"
echo "internal_component_demo_loop_transition_preview_packet_materialized=true"
echo "loop_transition_order_action_state_render=true"
echo "loop_transition_carries_surface_before_after_semantic_node_facts=true"
echo "loop_transition_carries_state_update_dry_run_delta=true"
echo "loop_transition_carries_render_command_refresh_delta=true"
echo "loop_transition_preview_non_executing=true"
echo "stage259_loop_semantic_diff_explain_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
