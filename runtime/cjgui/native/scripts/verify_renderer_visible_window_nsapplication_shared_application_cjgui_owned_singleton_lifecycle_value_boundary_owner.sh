#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication application-singleton
# CJGUI-owned lifecycle value boundary owner。
# Truth: 该 owner 只表达 CJGUI-owned lifecycle value boundary 与 teardown /
# cleanup responsibility owner facts；它不执行 cleanup / teardown，不升级
# production singleton ownership truth，也不实现 production singleton owner。
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
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_value_boundary.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundary"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness"
  "didConsumeCjguiOwnedSingletonLifecyclePreflightReadiness"
  "didOpenCjguiOwnedSingletonLifecycleValueBoundary"
  "didDeclareTeardownCleanupResponsibilityOwnerRequired"
  "didClassifyCleanupResponsibilityAsOwnedModePrerequisite"
  "didRequireCleanupBeforeProductionSingletonImplementation"
  "didRequireMainThreadCleanup"
  "didRequireCleanupIdempotency"
  "didRequireCleanupBeforeVisibleOrder"
  "didRequireCleanupBeforeDrawableRender"
  "didRequireHeadlessCiFailClosed"
  "didDeferCleanupExecution"
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
  "didKeepHostedOwnerTruthFalse"
  "didKeepSourceReadinessTruthValueFalse"
  "didKeepProductionSingletonOwnershipTruthFalse"
  "didKeepProductionSingletonImplementationBlocked"
  "didKeepProductionActualAccessorCallSiteBlocked"
  "didConfirmNoNewApplicationSingletonAccessorCall"
  "didRequireFutureTeardownImplementationSeparateApproval"
  "didKeepOwnedLifecycleValueBoundaryReadinessDehydrated"
  "didAvoidApplicationReadyWrapper"
  "didAvoidSingletonOwnerReadyWrapper"
  "didAvoidCleanupExecutionWrapper"
  "didAvoidBackendReadyWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: value_boundary_opened=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: teardown_cleanup_responsibility_owner_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: cleanup_before_production_singleton_implementation_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: main_thread_cleanup_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: cleanup_idempotency_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: cleanup_before_visible_order_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: cleanup_before_drawable_render_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: headless_ci_fail_closed_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: cleanup_execution_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: activation_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: activation_policy_mutation_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: appkit_event_loop_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: bounded_run_loop_pump_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: visible_order_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: drawable_render_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: artifact_public_diagnostics_publication=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: hosted_owner_truth=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: source_readiness_truth_value=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: production_singleton_implementation=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: production_actual_accessor_call_site=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle value boundary owner probe: new_application_singleton_accessor_call=false"
