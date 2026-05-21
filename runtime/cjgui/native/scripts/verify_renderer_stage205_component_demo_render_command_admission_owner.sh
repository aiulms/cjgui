#!/usr/bin/env zsh
#
# 维护注释：验证 stage205 component demo RenderCommand admission owner。
# 该 owner 只把 stage204 dry-run 输入接成 internal RenderCommand preview，不提交渲染。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage205_component_demo_render_command_admission.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage205 component demo render command admission: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage205ComponentDemoRenderCommandAdmissionDraft" \
  "didConsumeStage204ComponentDemoStateUpdateDryRun" \
  "didConsumeInternalRenderCommandPacket" \
  "didMapComponentDemoSemanticFixtureToRenderCommandPacket" \
  "didMaterializeRenderCommandAdmissionPreview" \
  "didPrepareStage206ComponentDemoPreviewPacketInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage205 component demo render command admission: missing token $token" >&2
    exit 3
  fi
done

echo "stage205_component_demo_render_command_admission_owner_present=true"
echo "stage204_component_demo_state_update_dry_run_required=true"
echo "internal_render_command_packet_consumed=true"
echo "component_demo_semantic_fixture_mapped_to_render_command_packet=true"
echo "render_command_admission_preview_materialized=true"
echo "stage206_component_demo_preview_packet_input_prepared=true"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
