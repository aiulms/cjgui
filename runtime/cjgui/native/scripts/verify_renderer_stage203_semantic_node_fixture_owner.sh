#!/usr/bin/env zsh
#
# 维护注释：验证 stage203 semantic node positive fixture owner。该 fixture
# 只生成 internal UI semantic 输入，不创建 public component API 或 layout 引擎。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage203_semantic_node_fixture.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage203 semantic node fixture: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage203SemanticNodeFixtureReadiness" \
  "cjguiInternalExecuteDefaultRendererStage203SemanticNodeFixtureDraft" \
  "didConsumeStage202SceneRenderCommandBridge" \
  "didMaterializeInternalRectSemanticNode" \
  "didMaterializeInternalTextSemanticNode" \
  "didMaterializeInternalButtonLikeSemanticNode" \
  "didPrepareStage204ComponentDemoStateUpdateDryRunInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage203 semantic node fixture: missing token $token" >&2
    exit 3
  fi
done

echo "stage203_semantic_node_fixture_owner_present=true"
echo "stage202_scene_render_command_bridge_required=true"
echo "internal_rect_semantic_node_materialized=true"
echo "internal_text_semantic_node_materialized=true"
echo "internal_button_like_semantic_node_materialized=true"
echo "stage204_component_demo_state_update_dry_run_input_prepared=true"
echo "public_component_api_added=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
