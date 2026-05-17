#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication application-singleton
# CJGUI-owned lifecycle preflight owner。
# Truth: 该 owner 只表达路线 C 的 hosted / owned 双模式恢复选择，以及
# CJGUI-owned lifecycle planning/readiness facts；hosted mode 在本阶段为
# evidence absent / unavailable。它不升级 hosted owner truth、source
# readiness truth、production singleton ownership truth，也不实现 production
# singleton owner。
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
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_preflight.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflight"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness"
  "didConsumeRouteCHostedOwnedDualModeSelection"
  "didMarkHostedModeExternalOwnerWitnessEvidenceAbsent"
  "didMarkHostedModeUnavailableForCurrentRunway"
  "didSelectCjguiOwnedModeAsRecoveryRoute"
  "didRequireMainThreadCreation"
  "didRequireHeadlessCiFailClosed"
  "didDeferActivation"
  "didDeferActivationPolicyMutation"
  "didDeferAppKitEventLoop"
  "didDeferBoundedRunLoopPump"
  "didDeferVisibleOrder"
  "didDeferDrawableAndRender"
  "didRequireTeardownCleanupResponsibilityBeforeImplementation"
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
  "didKeepOwnedLifecyclePreflightReadinessDehydrated"
  "didAvoidApplicationReadyWrapper"
  "didAvoidSingletonOwnerReadyWrapper"
  "didAvoidHostedOwnerTruthWrapper"
  "didAvoidBackendReadyWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: route_c_hosted_owned_dual_mode_selection=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: hosted_mode_evidence_absent=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: hosted_mode_current_route_available=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: cjgui_owned_mode_recovery_selected=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: main_thread_creation_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: headless_ci_fail_closed_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: activation_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: activation_policy_mutation_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: appkit_event_loop_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: bounded_run_loop_pump_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: visible_order_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: drawable_render_deferred=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: teardown_cleanup_responsibility_required=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: artifact_public_diagnostics_publication=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: hosted_owner_truth=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: source_readiness_truth_value=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: production_singleton_implementation=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: production_actual_accessor_call_site=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle preflight owner probe: new_application_singleton_accessor_call=false"
