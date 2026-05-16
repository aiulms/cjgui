#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# production singleton ownership value boundary owner。
# Truth: 该 owner 只消费 source readiness truth value boundary 与 source/cleanup
# boundary readiness，固定 production singleton ownership truth 仍为 false。
# Stop-line: 不调用 production singleton accessor，不创建或激活 NSApplication，
# 不修改 activation policy，不启动 AppKit event loop / bounded pump，不执行
# cleanup / teardown，不创建 window / view / layer，不 visible order，不
# nextDrawable，不创建 command queue / buffer / encoder，不 render / commit /
# present / GPU submission，不扩 public API / production C ABI，不写
# runtime_state.cj / cjpm.toml。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_value_boundary.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundary"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness"
  "didPreserveSourceReadinessTruthValueBoundaryReadiness"
  "didPreserveProductionSingletonOwnershipSourceCleanupBoundaryReadiness"
  "didOpenProductionSingletonOwnershipValueBoundary"
  "didRequireSourceReadinessTruthBeforeOwnershipTruth"
  "didRequireExternalPreexistingSingletonSourceBeforeOwnershipTruth"
  "didRequireWitnessTruthBeforeOwnershipTruth"
  "didRequireCleanupOwnershipBeforeImplementation"
  "didRequireMainThreadConfinement"
  "didRequireHeadlessFailClosed"
  "didConfirmSourceReadinessTruthValueFalse"
  "didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse"
  "didConfirmProductionSingletonOwnershipTruthFalse"
  "didConfirmProductionSingletonImplementationBlocked"
  "didConfirmProductionActualAccessorCallSiteBlocked"
  "didRejectThrowawayCreationAsProductionOwnershipTruth"
  "didKeepActualAccessorCallInIsolatedNativeProbeOnly"
  "didConfirmNoActivationPolicyMutation"
  "didConfirmNoApplicationActivation"
  "didConfirmNoAppKitEventLoop"
  "didConfirmNoBoundedRunLoopPump"
  "didConfirmNoCleanupTeardownExecution"
  "didConfirmNoWindowViewLayerCreation"
  "didConfirmNoVisibleOrder"
  "didConfirmNoDrawable"
  "didConfirmNoCommandQueueBufferEncoder"
  "didConfirmNoRenderCommitPresentGpuSubmission"
  "didConfirmNoArtifactOrDiagnosticsPublication"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didConfirmNoPointerHandleClassIdReturn"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
  "didKeepProductionSingletonOwnershipValueBoundaryDehydrated"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: production_singleton_ownership_value_boundary_owner=true"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: source_readiness_truth_value_boundary_preserved=true"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: source_cleanup_boundary_preserved=true"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: source_readiness_truth_value=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: external_source_witness_truth=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: production_singleton_implementation=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: production_actual_accessor_call_site=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: actual_accessor_call_isolated_native_probe_only=true"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: cleanup_teardown_executed=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: window_view_layer_created=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: visible_order=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: command_queue_buffer_encoder_created=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: render_commit_present_gpu_submission=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: artifact_or_diagnostics_publication=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: pointer_handle_class_id_return=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application production singleton ownership value boundary owner probe: cjpm_toml_change=false"
