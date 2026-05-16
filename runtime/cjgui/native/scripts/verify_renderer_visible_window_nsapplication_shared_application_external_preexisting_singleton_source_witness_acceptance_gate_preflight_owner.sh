#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# external preexisting singleton source witness acceptance gate preflight owner。
# Truth: acceptance gate preflight 只承接 payload validation preflight 的
# validated dehydrated payload 与 fail-closed classification；不得升级为
# witness truth、source readiness truth、production singleton owner、actual
# accessor production call site 或 native C ABI。
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
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_acceptance_gate_preflight.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflight"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflight"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadValidationPreflightReadiness"
  "didRequireValidatedPayloadBeforeAcceptanceGate"
  "didRequirePayloadValidationReadinessCarryForward"
  "didRequireValidatedPayloadVersionCarryForward"
  "didRequireValidatedExternalOwnerIdentityCarryForward"
  "didRequireValidatedPreexistingSingletonObservationCarryForward"
  "didRequireValidatedMainThreadObservationCarryForward"
  "didRequireValidatedSourceLifetimeCarryForward"
  "didRequireValidatedCleanupOwnershipCarryForward"
  "didRequireValidatedNoRendererAccessorInvariantCarryForward"
  "didRequireValidatedNoRendererCreationInvariantCarryForward"
  "didRequireClassificationPropagationToAcceptanceGate"
  "didRequireAcceptanceGateRemainPreTruth"
  "didRequireAcceptanceGateRemainDehydrated"
  "didRequireAcceptanceGateFailClosedWhenValidationMissing"
  "didRequireAcceptanceGateFailClosedWhenValidationBlocked"
  "didRequireAcceptanceGateFailClosedWhenInvariantMismatch"
  "didRequireHeadlessAcceptanceFailureRemainNonUserVisible"
  "didRejectPointerHandleClassIdAcceptancePayload"
  "didRejectNativeObjectAcceptancePayload"
  "didRejectDiagnosticsOrArtifactAcceptancePayload"
  "didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse"
  "didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse"
  "didConfirmProductionSingletonOwnershipTruthFalse"
  "didConfirmProductionSingletonImplementationBlocked"
  "didConfirmProductionActualAccessorCallSiteBlocked"
  "didKeepExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightValueOnly"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: witness_acceptance_gate_preflight_owner=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_payload_before_acceptance_gate_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: payload_validation_readiness_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_payload_version_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_external_owner_identity_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_preexisting_singleton_observation_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_main_thread_observation_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_source_lifetime_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_cleanup_ownership_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_no_renderer_accessor_invariant_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: validated_no_renderer_creation_invariant_carry_forward_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: classification_propagation_to_acceptance_gate_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: acceptance_gate_remain_pre_truth_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: acceptance_gate_remain_dehydrated_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: acceptance_gate_fail_closed_when_validation_missing_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: acceptance_gate_fail_closed_when_validation_blocked_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: acceptance_gate_fail_closed_when_invariant_mismatch_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: headless_acceptance_failure_non_user_visible_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: pointer_handle_class_id_acceptance_payload_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: native_object_acceptance_payload_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: diagnostics_or_artifact_acceptance_payload_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: external_preexisting_singleton_source_witness_truth=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: external_preexisting_singleton_source_readiness_truth=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: production_singleton_implementation_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: production_actual_accessor_call_site_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: cleanup_teardown_executed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: window_view_layer_created=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: visible_order=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: render_commit_present_gpu_submission=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: pointer_handle_class_id_return=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: artifact_or_diagnostics_publication=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness acceptance gate preflight owner probe: cjpm_toml_change=false"
