#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness D3 result-envelope
# renderer-state external packet provenance replay owner。它只做 source-level
# owner probe，不执行 runtime native probe，也不消费 D3 approval。
# Truth: focused external packet provenance-replay owner probe；验证 promotion
# admission input、external provenance replay contract、shape/provenance
# separation、current-shell replay denial、separate renderer-state write decision
# requirement 与 no-truth-upgrade facts。
# Stop-line: 不调用 application singleton accessor，不创建或激活 NSApplication，
# 不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行
# cleanup / teardown，不创建 visible window，不 visible order，不取 drawable，
# 不 render / commit / present / GPU submission，不扩 public API / production C
# ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketProvenanceReplayDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateExternalPacketPromotionAdmissionReadiness"
  "didConsumeD3ResultEnvelopeRendererStateExternalPacketPromotionAdmissionReadiness"
  "didOpenExternalPacketProvenanceReplayRoute"
  "didRequirePromotionAdmissionPacketReplay"
  "didRequireExternalMetalCapableProvenanceReplay"
  "didSeparateShapeAdmissionFromProvenanceReplay"
  "didDenyCurrentShellProvenanceReplay"
  "didRequireExternalValidatedPacketProductionBeforeReplay"
  "didRequireRendererStateWriteDecisionAfterExternalProvenance"
  "didConfirmProvenanceReplayDoesNotWriteRendererState"
  "didKeepExternalPacketProvenanceReplayDehydrated"
  "didRequireRuntimeStateLineCountInvariant"
  "didConfirmNoProductionTruthUpgrade"
  "didConfirmNoApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didAvoidSameShapePromotionAdmissionWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: promotion_admission_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: external_packet_provenance_replay_route_opened=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: promotion_admission_packet_replay_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: external_metal_capable_provenance_replay_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: shape_admission_separated_from_provenance_replay=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: current_shell_provenance_replay_denied=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: renderer_state_write_decision_after_external_provenance_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: provenance_replay_does_not_write_renderer_state=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: no_production_truth_upgrade_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay owner probe: same_shape_promotion_admission_wrapper=false"
