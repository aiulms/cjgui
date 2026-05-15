#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# cleanup / headless safety value owner。
# Truth: 只检查 runtime internal owner 的符号、上游 input 与停止线。
# Stop-line: 不调用 application singleton accessor，不创建 application，不
# activation，不修改 activation policy，不运行 event loop，不触发 native visible
# order，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不扩 public API。
# Same-shape Boundary Brake: cleanup / headless safety owner 不是 application-ready、
# visible-ready、drawable-ready、render-ready、backend-ready 或 state-write
# permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyAdmission"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness"
  "didConfirmCleanupCoOwnershipBeforeVisibleModeRequired"
  "didConfirmHeadlessSafetyFailClosedRoute"
  "didConfirmCiArtifactPolicyEvidenceOnly"
  "didConfirmMainThreadOwnershipProofBeforeAccessorCallRequired"
  "didConfirmTeardownProofBeforeVisibleModeRequired"
  "didConfirmActualApplicationSingletonAccessorCallStillBlocked"
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
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|commit\]|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' "$OWNER_FILE" "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: forbidden application/visible/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: runtime_owner_present=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: upstream_accessor_call_containment_policy=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: cleanup_co_ownership_required=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: headless_safety_fail_closed=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: ci_artifact_policy_evidence_only=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: main_thread_ownership_required=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: teardown_proof_required=true"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: application_singleton_accessor_called=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: application_created=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: event_loop_started=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: native_visible_order_implementation=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication shared-application cleanup headless safety owner probe: backend_ready_truth=false"
