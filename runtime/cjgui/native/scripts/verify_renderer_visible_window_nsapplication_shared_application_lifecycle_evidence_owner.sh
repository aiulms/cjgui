#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# lifecycle evidence owner。
# Truth: 只检查 runtime internal owner 的符号、上游 input 与停止线。
# Stop-line: 不调用 application singleton accessor，不创建 application，不
# activation，不修改 activation policy，不运行 event loop，不触发 native visible
# order，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不扩 public API。
# Same-shape Boundary Brake: lifecycle evidence owner 不是 application-ready、
# visible-ready、drawable-ready、render-ready、backend-ready 或 state-write
# permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceAdmission"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness"
  "didConfirmLifecycleOwnerEvidenceRequired"
  "didConfirmApplicationSingletonOwnershipEvidenceRequired"
  "didConfirmRunLoopExecutionEvidenceStillRequired"
  "didConfirmTeardownOrderingEvidenceStillRequired"
  "didConfirmHeadlessArtifactPolicyEvidenceOnly"
  "didConfirmSideEffectContainmentEvidenceStillRequired"
  "didConfirmActualApplicationSingletonAccessorCallStillBlocked"
  "didConfirmNoApplicationSingletonAccessorCall"
  "didConfirmApplicationSingletonCreationStillBlocked"
  "didConfirmApplicationActivationStillBlocked"
  "didConfirmEventLoopStillBlocked"
  "didConfirmNoPublicSurface"
  "didConfirmNoPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|commit\]|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' "$OWNER_FILE" "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: forbidden application/visible/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: runtime_owner_present=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: upstream_cleanup_headless_safety=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: lifecycle_owner_evidence_required=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: application_singleton_ownership_evidence_required=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: run_loop_execution_evidence_required=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: teardown_ordering_evidence_required=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: headless_artifact_policy_evidence_only=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: side_effect_containment_evidence_required=true"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: application_singleton_accessor_called=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: application_created=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: event_loop_started=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: native_visible_order_implementation=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication shared-application lifecycle evidence owner probe: backend_ready_truth=false"
