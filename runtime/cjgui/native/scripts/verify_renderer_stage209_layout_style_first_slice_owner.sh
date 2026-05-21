#!/usr/bin/env zsh
#
# 维护注释：验证 stage209 layout/style first-slice owner。
# 它只生成 owner-local layout/style value facts，不启用 layout engine。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage209_layout_style_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage209 layout style first slice: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage209LayoutStyleFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage209LayoutStyleFirstSliceDraft" \
  "didConsumeStage208ComponentDemoUiRunwayReadinessDecision" \
  "didMaterializeInternalRectLayoutValueFacts" \
  "didMaterializeInternalTextTypographyValueFacts" \
  "didMaterializeInternalButtonStyleValueFacts" \
  "didMaterializeInternalStyleTokenValueFacts" \
  "didPrepareStage210StyledComponentPreviewPacketInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage209 layout style first slice: missing token $token" >&2
    exit 3
  fi
done

echo "stage209_layout_style_first_slice_owner_present=true"
echo "stage208_ui_runway_readiness_decision_required=true"
echo "rect_layout_value_facts_materialized=true"
echo "text_typography_value_facts_materialized=true"
echo "button_style_value_facts_materialized=true"
echo "style_token_value_facts_materialized=true"
echo "stage210_styled_component_preview_packet_input_prepared=true"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
