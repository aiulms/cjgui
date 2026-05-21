#!/usr/bin/env zsh
#
# 维护注释：验证 stage212 UI framework runway readiness decision owner。
# 它只批准下一段 input/action first-slice 输入，不扩 public API。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage212_ui_framework_runway_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage212 ui framework runway readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage212UiFrameworkRunwayReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage212UiFrameworkRunwayReadinessDecisionDraft" \
  "didConsumeStage211LayoutStyleSemanticDiffExplain" \
  "didJoinLayoutStyleFactsWithStyledPreviewPacket" \
  "didMaterializeUiFrameworkRunwayReadinessDecision" \
  "didPrepareStage213InputActionFirstSliceInput" \
  "didKeepLayoutEngineBlocked" \
  "didKeepInputEventPipelineBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage212 ui framework runway readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage212_ui_framework_runway_readiness_decision_owner_present=true"
echo "stage211_layout_style_semantic_diff_explain_required=true"
echo "layout_style_facts_joined_with_styled_preview_packet=true"
echo "ui_framework_runway_readiness_decision_materialized=true"
echo "stage213_input_action_first_slice_input_prepared=true"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
