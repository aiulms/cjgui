#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness D3 result-envelope admission
# owner。它只做 source-level owner probe，不执行 runtime native probe，也不消费
# D3 approval。
# Truth: focused owner probe；验证 stage94 D3 environment recovery input、external
# Metal-capable shell packet、approval consumption proof、native result envelope
# schema、artifact containment 与 no-truth-upgrade admission facts。
# Stop-line: 不调用 application singleton accessor，不创建或激活 NSApplication，
# 不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行
# cleanup / teardown，不创建 visible window，不 visible order，不取 drawable，
# 不 render / commit / present / GPU submission，不扩 public API / production C
# ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_admission.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3EnvironmentRecoveryReadiness"
  "didOpenD3ResultEnvelopeAdmissionRoute"
  "didRequireExternalMetalCapableShellPacket"
  "didRequireHumanApprovalConsumptionProofInExternalPacket"
  "didRequireCapabilityPacketBeforeResultEnvelope"
  "didRequireNativeResultPacketSchema"
  "didRequireIntegerClassificationOnly"
  "didRequireSideEffectClassification"
  "didRequireArtifactContainmentProof"
  "didRequireNoPointerOrNativeObjectPayload"
  "didRequireNoProductionTruthUpgrade"
  "didKeepCurrentEnvironmentExecutionBlocked"
  "didKeepD3LimitedApprovalUnconsumedByDefaultDraft"
  "didConfirmNoApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didAvoidSameShapeRecoveryWrapper"
  "didKeepD3ResultEnvelopeAdmissionDehydrated"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: d3_result_envelope_admission_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: d3_environment_recovery_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: external_metal_capable_shell_packet_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: external_approval_consumption_proof_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: capability_packet_before_result_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: native_result_packet_schema_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: integer_classification_only_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: side_effect_classification_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: artifact_containment_proof_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: no_pointer_or_native_object_payload_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: no_production_truth_upgrade_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: current_environment_execution_blocked=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: d3_limited_approval_unconsumed_by_default_draft=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope admission owner probe: same_shape_recovery_wrapper=false"
