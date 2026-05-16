#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# preauthorized actual accessor first-slice owner。
# Truth: 该 owner 只消费 post-witness preflight 与 isolated / throwaway
# probe evidence，确认当前 automation 预授权解除上一轮 approval blocker；
# 不新增 production accessor call site，不形成 production singleton ownership truth。
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
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSlice"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSlice"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness"
  "didConsumeAutomationPreauthorizationForActualAccessorFirstSlice"
  "didResolvePreviousExplicitApprovalBlockerInsidePreauthorizedRunway"
  "didKeepActualAccessorCallInIsolatedNativeProbeOnly"
  "didConfirmThrowawayCreationEvidenceObserved"
  "didRejectThrowawayCreationAsProductionOwnershipTruth"
  "didConfirmNoProductionActualAccessorCallSite"
  "didConfirmNoProductionSingletonOwnerImplementation"
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
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: preauthorized_actual_accessor_first_slice_owner=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: post_witness_preflight_readiness_preserved=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: isolated_probe_evidence_readiness_preserved=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: throwaway_creation_probe_evidence_readiness_preserved=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: automation_preauthorization_consumed=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: previous_explicit_approval_blocker_resolved=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: actual_accessor_call_isolated_native_probe_only=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: throwaway_creation_evidence_observed=true"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: production_actual_accessor_call_site=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: cleanup_teardown_executed=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: window_view_layer_created=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: visible_order=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: command_queue_buffer_encoder_created=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: render_commit_present_gpu_submission=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: artifact_or_diagnostics_publication=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: pointer_handle_class_id_return=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application preauthorized actual accessor first-slice owner probe: cjpm_toml_change=false"
