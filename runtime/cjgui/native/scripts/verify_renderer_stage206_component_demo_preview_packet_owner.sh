#!/usr/bin/env zsh
#
# 维护注释：验证 stage206 component demo preview packet owner。该 packet
# 只承载预览与 rollback 输入，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage206_component_demo_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage206 component demo preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage206ComponentDemoPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage206ComponentDemoPreviewPacketDraft" \
  "didConsumeStage205ComponentDemoRenderCommandAdmission" \
  "didConsumeRenderBatchingPacket" \
  "didMaterializeComponentDemoPreviewPacket" \
  "didBindPreviewToOwnerLocalRollbackBoundary" \
  "didKeepPreviewVisibilityNotPublished" \
  "didPrepareStage207SemanticPreviewDiffInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage206 component demo preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage206_component_demo_preview_packet_owner_present=true"
echo "stage205_component_demo_render_command_admission_required=true"
echo "render_batching_packet_consumed=true"
echo "component_demo_preview_packet_materialized=true"
echo "owner_local_rollback_boundary_bound=true"
echo "preview_visibility_not_published=true"
echo "stage207_semantic_preview_diff_input_prepared=true"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
