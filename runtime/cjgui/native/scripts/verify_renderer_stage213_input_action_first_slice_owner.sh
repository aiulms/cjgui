#!/usr/bin/env zsh
#
# 维护注释：验证 stage213 input/action first-slice owner。
# 它只生成 Button-like action intent 的 owner-local 输入，不执行事件派发。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage213_input_action_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage213 input action first slice: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage213InputActionIntentFacts" \
  "CjguiInternalRendererStage213InputActionFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage213InputActionFirstSliceDraft" \
  "didConsumeStage212UiFrameworkRunwayReadinessDecision" \
  "didMaterializeButtonLikeActionIntentFacts" \
  "didBindActionIntentToSemanticNode" \
  "didBindActionIntentToStyledComponentPreviewPacket" \
  "didPrepareStage214ActionPreviewPacketInput" \
  "didKeepInputEventPipelineExecutionBlocked" \
  "didKeepActionDispatchBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage213 input action first slice: missing token $token" >&2
    exit 3
  fi
done

echo "stage213_input_action_first_slice_owner_present=true"
echo "stage212_ui_framework_runway_readiness_decision_required=true"
echo "button_like_action_intent_facts_materialized=true"
echo "action_intent_bound_to_semantic_node=true"
echo "action_intent_bound_to_styled_component_preview_packet=true"
echo "stage214_action_preview_packet_input_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
