#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# accessor call containment runtime owner。
# Truth: 只检查 runtime internal owner 的符号、上游 input、native
# containment facts 与停止线。
# Stop-line: 不调用 application singleton accessor，不创建 application，不
# activation，不修改 activation policy，不运行 event loop，不触发 native visible
# order，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不扩 public API。
# Same-shape Boundary Brake: accessor call containment owner 不是 application-ready、
# visible-ready、drawable-ready、render-ready、backend-ready 或 state-write
# permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness"
  "cjguiInternalObserveRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentValues"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_no_singleton_accessor_call"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_singleton_creation_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_main_thread_required"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_bounded_run_loop_required"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_auto_close_required"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_teardown_before_visible_required"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_non_user_visible_required"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_application_side_effect_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_policy_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_event_loop_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_visible_order_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_drawable_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_render_blocked"
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_backend_ready_truth_blocked"
  "didConfirmApplicationSingletonAccessorCallStillBlocked"
  "didConfirmNoApplicationSingletonAccessorCall"
  "didConfirmApplicationSingletonCreationStillBlocked"
  "didConfirmApplicationSideEffectStillBlocked"
  "didConfirmNoApplicationCreationOrActivation"
  "didConfirmNoPointerHandleClassIdReturn"
  "didConfirmNoPublicSurface"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: forbidden public runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|commit\]|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' "$OWNER_FILE" "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: forbidden application/visible/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: runtime_owner_present=true"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: upstream_accessor_call_preflight=true"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: native_side_effect_containment_c_abi=true"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: application_singleton_accessor_called=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: application_created=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: event_loop_started=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: native_visible_order_implementation=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication shared-application accessor call containment owner probe: backend_ready_truth=false"
