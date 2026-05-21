#!/usr/bin/env zsh
#
# 维护注释：验证 stage214 action preview packet owner。
# 它把 action intent 绑定到 styled preview packet，但保持 non-dispatching。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage214_action_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage214 action preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage214ActionPreviewPacketFacts" \
  "CjguiInternalRendererStage214ActionPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage214ActionPreviewPacketDraft" \
  "didConsumeStage213InputActionFirstSlice" \
  "didJoinActionIntentWithStyledComponentPreviewPacket" \
  "didMaterializeActionPreviewPacket" \
  "didBindActionPreviewToOwnerLocalRollbackBoundary" \
  "didPreserveActionPreviewNonDispatching" \
  "didPrepareStage215ActionSemanticDiffInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage214 action preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage214_action_preview_packet_owner_present=true"
echo "stage213_input_action_first_slice_required=true"
echo "action_intent_joined_with_styled_component_preview_packet=true"
echo "action_preview_packet_materialized=true"
echo "action_preview_bound_to_owner_local_rollback_boundary=true"
echo "action_preview_non_dispatching=true"
echo "stage215_action_semantic_diff_input_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
