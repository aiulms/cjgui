#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness D3 environment recovery owner。
# 它只做 source-level owner probe，不执行 runtime native probe，也不消费 D3
# approval。
# Truth: focused owner probe；验证 stage93 checkpoint input、Metal-unavailable
# recovery route、bounded native fail-closed packet、classifier、source/build guard 与
# focused recovery suite facts。
# Stop-line: 不调用 application singleton accessor，不创建或激活 NSApplication，
# 不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行
# cleanup / teardown，不创建 visible window，不 visible order，不取 drawable，
# 不 render / commit / present / GPU submission，不扩 public API / production C
# ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalReplayCheckpointReadiness"
  "didOpenD3EnvironmentRecoveryRoute"
  "didObserveCurrentShellMetalUnavailable"
  "didClassifyFailureDomainAsAutomationEnvironment"
  "didRequireExternalMetalCapableShellForD3Execution"
  "didKeepD3LimitedApprovalUnconsumed"
  "didKeepRuntimeNativeProbeExecutionBlockedByEnvironment"
  "didRequireBoundedNativeFailClosedPacket"
  "didRequireRecoveryClassifier"
  "didRequireSourceBuildRecoveryGuard"
  "didRequireFocusedRecoverySuite"
  "didConfirmReplayCheckpointReusable"
  "didConfirmCodeFailureDomainFalse"
  "didConfirmNoApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didAvoidSameShapeNoAccessorWrapper"
  "didKeepD3EnvironmentRecoveryDehydrated"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: d3_environment_recovery_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: explicit_approval_replay_checkpoint_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: current_shell_metal_unavailable=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: failure_domain=automation_environment"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: external_metal_capable_shell_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: d3_limited_approval_unconsumed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: bounded_native_fail_closed_packet_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: recovery_classifier_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: source_build_recovery_guard_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: focused_recovery_suite_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: replay_checkpoint_reusable=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery owner probe: same_shape_no_accessor_wrapper=false"
