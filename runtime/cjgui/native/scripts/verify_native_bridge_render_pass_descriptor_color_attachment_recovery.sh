#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 render pass descriptor color attachment recovery 仍停在 blocker facts。
# stop-line：不得新增 attachment configuration callable，不得创建 encoder，不 draw，
# 不 commit，不 present，不提交 GPU work，不执行 render，不返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
OWNER_PATH="${REPO_ROOT}/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj"
PLANNING_OWNER_PATH="${REPO_ROOT}/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment.cj"

if [[ ! -f "$OWNER_PATH" ]]; then
  echo "missing recovery owner: $OWNER_PATH" >&2
  exit 1
fi

required_owner_symbols=(
  "CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness"
  "cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft"
  "didConfirmProductionDrawableTokenLifetimeMissing"
  "didConfirmDescriptorDrawableLayerDeviceCleanupStillUnproven"
  "didConfirmColorAttachmentFirstSliceStillBlocked"
)
for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -q "$symbol" "$OWNER_PATH"; then
    echo "missing recovery owner symbol: $symbol" >&2
    exit 1
  fi
done

if ! grep -q "CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness" "$OWNER_PATH"; then
  echo "recovery owner must consume color attachment planning readiness" >&2
  exit 1
fi

if ! grep -q "didConfirmProductionDrawableTextureLifecycleMissing" "$PLANNING_OWNER_PATH"; then
  echo "planning owner no longer exposes drawable texture lifecycle blocker" >&2
  exit 1
fi

if grep -Eq 'render_pass_descriptor_color_attachment_(configure|set|bind|runtime_call)' "$HEADER_PATH" "$SOURCE_PATH"; then
  echo "forbidden production color attachment configuration callable found" >&2
  exit 1
fi

if grep -Eq 'renderCommandEncoder|MTLRenderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|newRenderPipelineState|dispatchThreadgroups' "$SOURCE_PATH"; then
  echo "forbidden encoder / draw / present / GPU path found" >&2
  exit 1
fi

if grep -Eq 'cjgui_native_bridge_[A-Za-z0-9_]+\([^;{)]*\)\s*\*|void\s*\*\s+cjgui_native_bridge_|id\s+cjgui_native_bridge_|Class\s+cjgui_native_bridge_|uintptr_t\s+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge public C ABI header" >&2
  exit 1
fi

printf "%s\n" "color_attachment_recovery_route=recovery_only"
printf "%s\n" "production_drawable_texture_lifetime=false"
printf "%s\n" "descriptor_drawable_cleanup_coownership=false"
printf "%s\n" "color_attachment_configured=false"
printf "%s\n" "encoder_created=false"
printf "%s\n" "draw_called=false"
printf "%s\n" "commit_called=false"
printf "%s\n" "present_called=false"
printf "%s\n" "gpu_work_submitted=false"
printf "%s\n" "render_executed=false"
printf "%s\n" "render_pass_descriptor_color_attachment_recovery_probe=passed"
