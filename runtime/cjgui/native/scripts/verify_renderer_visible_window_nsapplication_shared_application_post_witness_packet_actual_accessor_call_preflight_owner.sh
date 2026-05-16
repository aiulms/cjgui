#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# post-witness-packet actual accessor call preflight owner。
# Truth: 该 owner 只打开 post-witness-packet actual-call preflight
# revalidation，不执行 actual application singleton accessor call，不升级
# witness truth、source readiness truth 或 production singleton ownership truth。
# Stop-line: production runtime/native bridge 不创建或激活 NSApplication，不修改
# activation policy，不启动 AppKit event loop / bounded pump，不执行 cleanup /
# teardown，不创建 window / view / layer，不 visible order，不 nextDrawable，不创建
# command queue / buffer / encoder，不 render / commit / present / GPU submission，
# 不写 artifact / diagnostics publication，不扩 public API / production C ABI，不写
# runtime_state.cj / cjpm.toml。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflight"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness"
  "didOpenPostWitnessPacketActualAccessorCallPreflightRevalidation"
  "didConfirmOnlyActualCallPreflightOpened"
  "didConfirmNoActualAccessorCallImplementation"
  "didConfirmNoProductionActualAccessorCallSite"
  "didRejectPacketTruthAdmissionAsWitnessTruth"
  "didRejectPacketTruthAdmissionAsSourceReadinessTruth"
  "didRejectPacketTruthAdmissionAsProductionSingletonOwnershipTruth"
  "didRequireExplicitHumanDecisionBeforeActualCallFirstSlice"
  "didRequireMainThreadConfinedFutureFirstSlice"
  "didRequireIsolatedProbeFirstFutureFirstSlice"
  "didConfirmNoActivationPolicyMutation"
  "didConfirmNoApplicationActivation"
  "didConfirmNoAppKitEventLoop"
  "didConfirmNoBoundedRunLoopPump"
  "didConfirmNoCleanupTeardownExecution"
  "didConfirmNoWindowViewLayerCreation"
  "didConfirmNoVisibleOrder"
  "didConfirmNoDrawable"
  "didConfirmNoRender"
  "didConfirmNoArtifactPublication"
  "didConfirmNoPublicApi"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoPointerHandleClassIdReturn"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
  "didKeepPostWitnessPacketActualAccessorCallPreflightValueOnly"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: post_witness_packet_actual_accessor_call_preflight_owner=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: witness_packet_truth_admission_preflight_readiness_preserved=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: actual_accessor_call_preflight_guard_readiness_preserved=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: only_actual_call_preflight_opened=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: actual_accessor_call_implementation=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: production_actual_accessor_call_site=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: packet_truth_admission_as_witness_truth=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: packet_truth_admission_as_source_readiness_truth=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: packet_truth_admission_as_production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: explicit_human_decision_before_actual_call_first_slice_required=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: main_thread_confined_future_first_slice_required=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: isolated_probe_first_future_first_slice_required=true"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: application_singleton_accessor_called=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: application_created=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: cleanup_teardown_executed=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: window_view_layer_created=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: visible_order=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: render_commit_present_gpu_submission=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: artifact_or_diagnostics_publication=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: pointer_handle_class_id_return=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application post-witness-packet actual accessor call preflight owner probe: cjpm_toml_change=false"
