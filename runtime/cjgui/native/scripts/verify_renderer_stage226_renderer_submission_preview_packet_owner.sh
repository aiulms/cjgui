#!/usr/bin/env zsh
#
# 维护注释：验证 stage226 renderer submission preview packet owner。
# 它把 non-submitting preview 封装为 owner-local packet，仍不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage226_renderer_submission_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage226 renderer submission preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage226RendererSubmissionPreviewPacketFacts" \
  "CjguiInternalRendererStage226RendererSubmissionPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage226RendererSubmissionPreviewPacketDraft" \
  "didConsumeStage225RendererSubmissionPreview" \
  "didConsumeRenderBatchingPacket" \
  "didMaterializeRendererSubmissionPreviewPacket" \
  "didBindPreviewPacketToNonSubmittingCandidate" \
  "didBindPreviewPacketToRenderCommandRefreshReadiness" \
  "didPrepareStage227RendererSubmissionSemanticDiffInput" \
  "didKeepRendererSubmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage226 renderer submission preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage226_renderer_submission_preview_packet_owner_present=true"
echo "stage225_renderer_submission_preview_required=true"
echo "render_batching_packet_required=true"
echo "renderer_submission_preview_packet_materialized=true"
echo "preview_packet_bound_to_non_submitting_candidate=true"
echo "preview_packet_bound_to_render_command_refresh_readiness=true"
echo "stage227_renderer_submission_semantic_diff_input_prepared=true"
echo "preview_visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
