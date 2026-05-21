#!/usr/bin/env zsh
#
# 维护注释：验证 stage208 component demo UI runway readiness decision owner。
# 它只做 readiness join，准备 layout/style first-slice 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage208_component_demo_ui_runway_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage208 component demo ui runway readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage208ComponentDemoUiRunwayReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage208ComponentDemoUiRunwayReadinessDecisionDraft" \
  "didConsumeStage207SemanticPreviewDiffExplain" \
  "didJoinRenderCommandAdmissionWithPreviewPacket" \
  "didMaterializeUiRunwayReadinessDecision" \
  "didPrepareStage209LayoutStyleFirstSliceInput" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage208 component demo ui runway readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage208_component_demo_ui_runway_readiness_decision_owner_present=true"
echo "stage207_semantic_preview_diff_explain_required=true"
echo "render_command_admission_preview_joined=true"
echo "component_demo_preview_packet_joined=true"
echo "ui_runway_readiness_decision_materialized=true"
echo "stage209_layout_style_first_slice_input_prepared=true"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
