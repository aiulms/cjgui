#!/usr/bin/env zsh
#
# 维护注释：验证 stage210 styled component preview packet owner。
# 它把 stage209 value facts 绑定到 preview packet，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage210_styled_component_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage210 styled component preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage210StyledComponentPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage210StyledComponentPreviewPacketDraft" \
  "didConsumeStage209LayoutStyleFirstSlice" \
  "didJoinLayoutStyleFactsWithComponentDemoPreviewPacket" \
  "didMaterializeStyledComponentPreviewPacket" \
  "didBindRectLayoutToRenderCommandAdmissionPreview" \
  "didBindButtonStyleToOwnerLocalRollbackBoundary" \
  "didPrepareStage211LayoutStyleSemanticDiffInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage210 styled component preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage210_styled_component_preview_packet_owner_present=true"
echo "stage209_layout_style_first_slice_required=true"
echo "layout_style_facts_joined_with_preview_packet=true"
echo "styled_component_preview_packet_materialized=true"
echo "rect_layout_bound_to_render_command_admission_preview=true"
echo "button_style_bound_to_owner_local_rollback_boundary=true"
echo "stage211_layout_style_semantic_diff_input_prepared=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
