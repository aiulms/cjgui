#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage104 bounded result-envelope admission 到
# renderer-state write-decision join owner。它只做 source-level owner probe，
# 不执行 runtime native probe。
# Stop-line: 不调用 application accessor，不扩 native bridge / public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness"
  "didConsumeBoundedResultEnvelopeAdmissionReadiness"
  "didConsumeRendererStateWriteDecisionContractReadiness"
  "didOpenBoundedAdmissionWriteDecisionJoinPreflightRoute"
  "didRequireAdmittedBoundedResultEnvelopeInput"
  "didRequireIndependentRendererStateWriteDecisionContractInput"
  "didBindAdmittedEnvelopeToWriteDecisionContract"
  "didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly"
  "didConfirmWriteDecisionContractIsNotWritePermission"
  "didRequireProductionWriteAdmissionAfterJoinPreflight"
  "didKeepRendererStateWriteBlockedAfterJoinPreflight"
  "didConfirmNoProductionTruthUpgrade"
  "didConfirmNoBackendReadyTruthUpgrade"
  "didConfirmNoProductionApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didConfirmNoRendererStateWrite"
  "didAvoidAdmissionContractOrExternalPacketWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: d3_bounded_result_envelope_renderer_state_write_decision_join_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: bounded_result_envelope_admission_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: independent_write_decision_contract_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: admitted_bounded_result_envelope_input_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: independent_write_decision_contract_input_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: guarded_write_decision_join_preflight_route=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: bounded_envelope_remains_isolated_evidence_only=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: write_decision_contract_is_not_write_permission=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: production_write_admission_after_join_preflight_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: renderer_state_write_after_join_preflight_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: result_envelope_promoted_to_production_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: backend_ready_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join owner probe: admission_contract_or_external_packet_wrapper=false"
