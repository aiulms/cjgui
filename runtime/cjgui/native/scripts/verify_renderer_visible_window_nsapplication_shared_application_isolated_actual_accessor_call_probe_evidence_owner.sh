#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# isolated actual accessor call probe evidence owner。
# Truth: 只允许 isolated native probe 承载 actual accessor call，并只返回
# integer classification / dehydrated facts。
# Stop-line: production runtime/native bridge 不创建或激活 NSApplication，不修改
# activation policy，不启动 AppKit event loop / bounded pump，不创建 window、
# drawable 或 renderer resource，不写 artifact / diagnostics publication，不扩
# public API 或 production C ABI，不写 runtime_state.cj / cjpm.toml。
# Same-shape Boundary Brake: probe evidence 不是 application-ready、
# accessor-ready、visible-ready、drawable-ready、render-ready 或 backend-ready。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj"
NATIVE_PROBE="$ROOT_DIR/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

if [[ ! -f "$NATIVE_PROBE" ]]; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: missing native probe $NATIVE_PROBE" >&2
  exit 4
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness"
  "didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice"
  "didConfineActualAccessorCallToIsolatedNativeProbe"
  "didRequireMainThreadGateBeforeActualAccessorCall"
  "didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent"
  "didFailClosedWhenPreexistingApplicationMissing"
  "didReturnIntegerClassificationOnly"
  "didReturnDehydratedFactsOnly"
  "didClassifySideEffectBeforeAndAfterAccessor"
  "didClassifyNilAccessorReturnAsFailure"
  "didClassifySingletonCreationAsFailure"
  "didConfirmNoApplicationCreation"
  "didConfirmNoActivationPolicyMutation"
  "didConfirmNoApplicationActivation"
  "didConfirmNoAppKitEventLoop"
  "didConfirmNoBoundedRunLoopPump"
  "didConfirmNoWindowCreation"
  "didConfirmNoVisibleOrder"
  "didConfirmNoDrawable"
  "didConfirmNoRender"
  "didConfirmNoArtifactPublication"
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
    echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: missing $symbol" >&2
    exit 5
  fi
done

required_probe_tokens=(
  "sharedApplication"
  "isMainThread"
  "NSApp"
  "CJGUI_NSAPP_SHARED_APPLICATION_ISOLATED_PROBE_ALLOW_ACTUAL_CALL"
  "print_int(\"classification\""
  "print_text(\"side_effect_classification\""
  "print_bool(\"accessor_call_attempted\""
  "print_bool(\"application_created\""
  "print_bool(\"main_thread_gate_preserved\""
  "print_bool(\"dehydrated_facts_only\""
)

for token in "${required_probe_tokens[@]}"; do
  if ! grep -F "$token" "$NATIVE_PROBE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: native probe missing $token" >&2
    exit 6
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: forbidden runtime surface found" >&2
  exit 7
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*NSApplication[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: forbidden production application/visible/render token found" >&2
  exit 8
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep -E '^\+' | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*NSApplication[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: forbidden production native bridge diff found" >&2
  exit 8
fi

if grep -E 'setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|\[[[:space:]]*(NSApplication|NSWindow)[[:space:]]+(alloc|new|init)\]' "$NATIVE_PROBE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: forbidden native probe side-effect token found" >&2
  exit 9
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: protected path modified" >&2
  exit 10
fi

echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: native_probe=$NATIVE_PROBE"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: explicit_human_approval_for_isolated_actual_call_first_slice=true"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: isolated_native_probe_only=true"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: main_thread_gate_required=true"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: fail_closed_when_preexisting_application_missing=true"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: integer_classification_only=true"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: dehydrated_facts_only=true"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: application_created=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: nswindow_created=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: render_executed=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: artifact_write=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: artifact_publication=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application isolated actual accessor call probe evidence owner probe: cjpm_toml_change=false"
