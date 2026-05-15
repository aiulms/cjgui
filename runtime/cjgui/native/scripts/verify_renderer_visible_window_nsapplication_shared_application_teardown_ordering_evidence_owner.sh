#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# teardown ordering evidence owner。
# Truth: 只检查 runtime internal owner 的符号、上游 input 与停止线。
# Stop-line: 不执行 teardown，不运行 AppKit event loop，不实现 bounded pump，
# 不调用 application singleton accessor，不创建 application，不 activation，不修改
# activation policy，不触发 native visible order，不获取 drawable，不创建 encoder，
# 不 draw，不提交 GPU work，不扩 public API。
# Same-shape Boundary Brake: teardown ordering evidence owner 不是 teardown
# execution permission、event-loop permission、visible-ready、drawable-ready、
# render-ready、backend-ready 或 state-write permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceAdmission"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness"
  "didConfirmTeardownOrderingEvidenceStillRequired"
  "didConfirmTeardownBeforeVisibleEvidenceRequired"
  "didConfirmBoundedOwnerShutdownEvidenceRequired"
  "didConfirmStopConditionBeforeTeardownEvidenceRequired"
  "didConfirmAutoCloseCleanupEvidenceRequired"
  "didConfirmFailClosedTeardownRouteRequired"
  "didConfirmActualTeardownExecutionStillBlocked"
  "didConfirmActualEventLoopStillBlocked"
  "didConfirmActualRunLoopPumpStillBlocked"
  "didConfirmActualApplicationSingletonAccessorCallStillBlocked"
  "didConfirmApplicationSingletonCreationStillBlocked"
  "didConfirmApplicationActivationStillBlocked"
  "didConfirmNoPublicSurface"
  "didConfirmNoPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|commit\]|terminate|stop:|run\]|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' "$OWNER_FILE" "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: forbidden application/visible/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: runtime_owner_present=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: upstream_run_loop_evidence=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: teardown_ordering_evidence_required=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: teardown_before_visible_evidence_required=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: bounded_owner_shutdown_evidence_required=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: stop_condition_before_teardown_evidence_required=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: auto_close_cleanup_evidence_required=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: fail_closed_teardown_route_required=true"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: actual_teardown_execution=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: application_singleton_accessor_called=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: application_created=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: native_visible_order_implementation=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication shared-application teardown ordering evidence owner probe: backend_ready_truth=false"
