#!/usr/bin/env zsh
#
# 维护注释：验证 stage225 renderer submission preview owner。
# 它只生成 non-submitting submission preview，不触发真实 renderer submission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage225_renderer_submission_preview_after_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage225 renderer submission preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage225RendererSubmissionPreviewAfterRenderCommandRefreshDraft" \
  "didConsumeStage224RenderCommandRefreshReadinessDecision" \
  "didMaterializeRendererSubmissionPreview" \
  "didClassifySubmissionAsNonSubmitting" \
  "didBindSubmissionPreviewToButtonLikeSemanticNode" \
  "didBindSubmissionPreviewToRefreshedRenderCommandPacket" \
  "didPrepareStage226RendererSubmissionPreviewPacketInput" \
  "didKeepRendererSubmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage225 renderer submission preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage225_renderer_submission_preview_owner_present=true"
echo "stage224_render_command_refresh_readiness_decision_required=true"
echo "internal_render_command_packet_required=true"
echo "renderer_submission_preview_materialized=true"
echo "renderer_submission_candidate_non_submitting=true"
echo "button_like_semantic_node_bound_to_submission_preview=true"
echo "refreshed_render_command_packet_bound_to_submission_preview=true"
echo "stage226_renderer_submission_preview_packet_input_prepared=true"
echo "owner_acceptance_granted=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
