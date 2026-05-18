#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 D3 bounded runtime execution owner source。
# Truth: 只做 owner/source probe；不执行 native probe，不创建 NSApplication /
# NSWindow / CAMetalLayer，不写 renderer state，不扩 native bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_tokens=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedRuntimeExecutionFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedRuntimeExecutionReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedRuntimeExecutionFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedRuntimeExecutionReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedRuntimeExecutionDraft"
  "didConsumeRendererStateTwoKeyHandoffReadiness"
  "didRequireCapabilityDetectorBeforeExecution"
  "didAllowAutomationStandingD3WhenMetalCapable"
  "didPermitIsolatedVisibleWindowProbeOnly"
  "didRequireResultEnvelopeFromProbe"
  "didConfirmNonMetalShellDoesNotExecuteNativeProbe"
  "didConfirmResultEnvelopeIsNotProductionTruth"
  "didAvoidApprovalHandoffWrapper"
)
for token in "${required_tokens[@]}"; do
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: missing token $token" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: public or foreign declaration found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: forbidden production application/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: protected path modified" >&2
  exit 7
fi

echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: route_classification=d3_bounded_runtime_execution_owner"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: d3_bounded_runtime_execution_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: two_key_handoff_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: capability_detector_before_execution_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: automation_standing_d3_autonomy_bounded=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: isolated_visible_window_probe_only=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: result_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: non_metal_shell_native_probe_execution_denied=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: result_envelope_is_not_production_truth=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution owner: production_public_c_abi_added=false"
