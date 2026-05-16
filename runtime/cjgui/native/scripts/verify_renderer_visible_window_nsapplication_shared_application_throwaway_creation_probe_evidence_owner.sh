#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# throwaway creation probe evidence owner。
# Truth: throwaway singleton creation 只允许出现在 isolated native probe first
# slice 中，只返回 integer classification / dehydrated facts，不形成 production
# singleton ownership truth。
# Stop-line: production runtime/native bridge 不 activation，不修改 activation
# policy，不启动 run / stop / terminate，不创建 NSWindow / NSView /
# CAMetalLayer，不 visible order，不 nextDrawable，不创建 command queue / buffer /
# encoder，不 render / commit / present / GPU submission，不写 artifact /
# diagnostics publication，不扩 public API / production C ABI，不写 runtime_state.cj
# / cjpm.toml。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj"
NATIVE_PROBE="$ROOT_DIR/native/scripts/verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

if [[ ! -f "$NATIVE_PROBE" ]]; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: missing native probe $NATIVE_PROBE" >&2
  exit 4
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidence"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness"
  "didConfirmExplicitHumanApprovalForThrowawayCreationProbeFirstSlice"
  "didConfineThrowawayCreationToIsolatedNativeProbe"
  "didAllowNsApplicationSharedApplicationToCreateThrowawaySingleton"
  "didRecordThrowawayCreationEvidenceNotProductionOwnershipTruth"
  "didObserveAccessorReturnOnly"
  "didObserveSingletonExistenceOnly"
  "didRequireMainThreadConfinement"
  "didRequireFailClosedClassification"
  "didReturnIntegerClassificationOnly"
  "didReturnDehydratedFactsOnly"
  "didConfirmNoActivationPolicyMutation"
  "didConfirmNoApplicationActivation"
  "didConfirmNoRunStopTerminate"
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
  "didConfirmNoRendererStateWrite"
  "didConfirmNoBackendReadyTruth"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: missing $symbol" >&2
    exit 5
  fi
done

required_probe_tokens=(
  "sharedApplication"
  "isMainThread"
  "NSApp"
  "CJGUI_NSAPP_SHARED_APPLICATION_THROWAWAY_PROBE_ALLOW_ACTUAL_CALL"
  "throwaway_creation_evidence"
  "production_singleton_ownership_truth"
  "print_int(\"classification\""
  "print_text(\"side_effect_classification\""
  "print_bool(\"accessor_call_attempted\""
  "print_bool(\"accessor_returned_nonnull\""
  "print_bool(\"throwaway_application_created\""
  "print_bool(\"main_thread_confined\""
  "print_bool(\"dehydrated_facts_only\""
)

for token in "${required_probe_tokens[@]}"; do
  if ! grep -F "$token" "$NATIVE_PROBE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: native probe missing $token" >&2
    exit 6
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: forbidden runtime surface found" >&2
  exit 7
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: forbidden production application/visible/render token found" >&2
  exit 8
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep -E '^\+' | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: forbidden production native bridge diff found" >&2
  exit 9
fi

if grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|\[[[:space:]]*(NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$NATIVE_PROBE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: forbidden native probe side-effect token found" >&2
  exit 10
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: protected path modified" >&2
  exit 11
fi

echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: native_probe=$NATIVE_PROBE"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: explicit_human_approval_for_throwaway_creation_probe_first_slice=true"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: isolated_native_probe_only=true"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: throwaway_creation_evidence=true"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: integer_classification_only=true"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: dehydrated_facts_only=true"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: run_stop_terminate_called=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: window_view_layer_created=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: command_queue_buffer_encoder_created=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: render_commit_present_gpu_submission=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: artifact_or_diagnostics_publication=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application throwaway creation probe evidence owner probe: cjpm_toml_change=false"
