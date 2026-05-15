#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window visible-order policy value owner。
# Truth: 只检查 runtime internal policy owner 的符号、上游输入与停止线。
# Stop-line: 不触发 native visible order，不创建 AppKit application side effect，
# 不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不扩 public API。
# Same-shape Boundary Brake: policy owner 不是 visible-ready、drawable-ready、
# render-ready、backend-ready 或 state-write permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_visible_order_policy.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer visible-order policy owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowVisibleOrderPolicyFacts"
  "CjguiInternalRendererVisibleWindowVisibleOrderPolicyAdmission"
  "CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness"
  "cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyFacts"
  "cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyAdmission"
  "cjguiInternalBuildRendererVisibleWindowVisibleOrderPolicyReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft"
  "CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness"
  "didConfirmApplicationOwnershipStillPolicyOnly"
  "didConfirmApplicationCreationStillDeferred"
  "didConfirmActivationStillDeferred"
  "didRequireBoundedRunLoopBeforeVisibleOrder"
  "didRequireAutoCloseBeforeVisibleOrderSmoke"
  "didKeepHeadlessCiFailClosedRoute"
  "didConfirmNoNativeVisibleOrderImplementation"
  "didConfirmNoProductionDrawablePermission"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer visible-order policy owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer visible-order policy owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'makeKeyAndOrderFront|orderFront|activateIgnoringOtherApps|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable' "$OWNER_FILE" "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui renderer visible-order policy owner probe: forbidden visible/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer visible-order policy owner probe: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer visible-order policy owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer visible-order policy owner probe: runtime_owner_present=true"
echo "cjgui renderer visible-order policy owner probe: upstream_content_view_attachment=true"
echo "cjgui renderer visible-order policy owner probe: native_visible_order_implementation=false"
echo "cjgui renderer visible-order policy owner probe: public_api_modified=false"
echo "cjgui renderer visible-order policy owner probe: renderer_state_write=false"
echo "cjgui renderer visible-order policy owner probe: backend_ready_truth=false"
