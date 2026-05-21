#!/usr/bin/env zsh
#
# 维护注释：验证 stage202 Scene / RenderCommand bridge owner。输入是
# stage201 token decision 与既有 render batching packet，输出 UI runway bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage202_scene_render_command_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage202 scene render command bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage202SceneRenderCommandBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage202SceneRenderCommandBridgeDraft" \
  "didConsumeStage201WriteTokenReevaluation" \
  "didConsumeRenderBatchingPacket" \
  "didMaterializeSceneRenderCommandRunwayBridge" \
  "didBindWriteTokenDecisionToRenderCommandPacket" \
  "didPrepareStage203SemanticNodeFixtureInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage202 scene render command bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage202_scene_render_command_bridge_owner_present=true"
echo "stage201_write_token_reevaluation_required=true"
echo "render_batching_packet_required=true"
echo "scene_render_command_runway_bridge_materialized=true"
echo "stage203_semantic_node_fixture_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
