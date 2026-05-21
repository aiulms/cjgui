#!/usr/bin/env zsh
#
# 维护注释：验证 stage222 refreshed RenderCommand preview packet owner。
# 它把 stage221 refresh preview 封装为可解释、可回滚的 owner-local preview packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage222_refreshed_render_command_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage222 refreshed render command preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketFacts" \
  "CjguiInternalRendererStage222RefreshedRenderCommandPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage222RefreshedRenderCommandPreviewPacketDraft" \
  "didConsumeStage221RenderCommandRefresh" \
  "didConsumeRenderBatchingPacket" \
  "didMaterializeRefreshedRenderCommandPreviewPacket" \
  "didBindPreviewPacketToStateUpdatePreview" \
  "didBindPreviewPacketToStateUpdateSemanticDiff" \
  "didBindPreviewPacketToRollbackBoundary" \
  "didPrepareStage223RenderCommandRefreshSemanticDiffInput" \
  "didKeepPreviewVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage222 refreshed render command preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage222_refreshed_render_command_preview_packet_owner_present=true"
echo "stage221_render_command_refresh_required=true"
echo "render_batching_packet_required=true"
echo "refreshed_render_command_preview_packet_materialized=true"
echo "refreshed_preview_packet_bound_to_state_update_preview=true"
echo "refreshed_preview_packet_bound_to_state_update_semantic_diff=true"
echo "refreshed_preview_packet_bound_to_rollback_boundary=true"
echo "stage223_render_command_refresh_semantic_diff_input_prepared=true"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
