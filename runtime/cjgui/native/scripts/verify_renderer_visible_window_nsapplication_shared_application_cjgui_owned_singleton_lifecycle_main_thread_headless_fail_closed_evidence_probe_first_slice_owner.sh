#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication application-singleton
# CJGUI-owned lifecycle main-thread / headless fail-closed evidence probe first
# slice owner。
# Truth: 该 owner 只表达 scan-only main-thread confinement evidence 与
# headless / CI fail-closed evidence；它不创建 singleton，不调用 application
# accessor，不扩展 native bridge，不执行 cleanup / teardown，也不升级
# production singleton ownership truth。
# Stop-line: 不调用 application singleton accessor，不创建或激活
# NSApplication，不修改 activation policy，不启动 AppKit event loop /
# bounded pump，不执行 cleanup / teardown，不创建 window / view / layer，
# 不 visible order，不 nextDrawable，不创建 command queue / buffer /
# encoder，不 render / commit / present / GPU submission，不扩 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSlice"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness"
  "didConsumeMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness"
  "didOpenMainThreadHeadlessFailClosedEvidenceProbeFirstSlice"
  "didRecordScanOnlyMainThreadConfinementEvidence"
  "didRecordScanOnlyHeadlessFailClosedEvidence"
  "didConfirmScanOnlyNoSingletonCreation"
  "didConfirmScanOnlyNoApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoRuntimeProbeExecution"
  "didCarryForwardNoSideEffectEvidenceOnly"
  "didCarryForwardTeardownCleanupResponsibilityOwnerRequired"
  "didCarryForwardMainThreadCreationConfinement"
  "didCarryForwardMainThreadCleanupConfinement"
  "didCarryForwardHeadlessCiFailClosedBeforeSingletonCreation"
  "didDeferProductionSingletonOwnerImplementation"
  "didDeferApplicationSingletonAccessorCall"
  "didDeferCleanupTeardownExecution"
  "didDeferActivation"
  "didDeferActivationPolicyMutation"
  "didDeferAppKitEventLoop"
  "didDeferBoundedRunLoopPump"
  "didDeferVisibleOrder"
  "didDeferDrawableAndRender"
  "didBlockArtifactPublicDiagnosticsPublication"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didKeepProductionSingletonOwnershipTruthFalse"
  "didKeepEvidenceProbeFirstSliceReadinessDehydrated"
  "didRequireFutureEvidenceProbeNativeSliceSeparateBoundary"
  "didAvoidApplicationReadyWrapper"
  "didAvoidSingletonOwnerReadyWrapper"
  "didAvoidBackendReadyWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: evidence_probe_first_slice_opened=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: scan_only_main_thread_confinement_evidence_recorded=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: scan_only_headless_fail_closed_evidence_recorded=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: scan_only_no_singleton_creation=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: scan_only_no_application_accessor_call=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: runtime_probe_execution=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: no_side_effect_evidence_only=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: production_singleton_owner_implementation=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: cleanup_teardown_execution=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: activation_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: activation_policy_mutation_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: appkit_event_loop_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: bounded_run_loop_pump_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: visible_order_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: drawable_render_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle main-thread headless fail-closed evidence probe first slice owner probe: production_singleton_ownership_truth=false"
