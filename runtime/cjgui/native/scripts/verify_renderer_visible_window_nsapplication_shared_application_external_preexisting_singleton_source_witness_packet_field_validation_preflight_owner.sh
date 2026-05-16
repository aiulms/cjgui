#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication shared-application
# external preexisting singleton source witness packet field validation
# preflight owner。
# Truth: packet field validation preflight 只消费 witness packet recovery
# preflight，固定 packet field validation gate、field-specific fail-closed
# checks 与 dehydrated validation result；不得升级为 witness truth、source
# readiness truth、production singleton owner、actual accessor production call
# site 或 native C ABI。
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
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_field_validation_preflight.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflight"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflight"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketRecoveryPreflightReadiness"
  "didRequireWitnessPacketRecoveryPreflightBeforeFieldValidation"
  "didRequirePacketVersionFieldValidated"
  "didRequireExternalOwnerIdentityFieldValidated"
  "didRequirePreexistingSingletonObservedBeforeRendererFieldValidated"
  "didRequireMainThreadObservationFieldValidated"
  "didRequireSourceLifetimeCoversRuntimeAdmissionFieldValidated"
  "didRequireCleanupOwnershipRetainedByExternalSourceFieldValidated"
  "didRequireRendererNonCreationInvariantFieldValidated"
  "didRequireRendererNonAccessorInvariantFieldValidated"
  "didRequireHeadlessFailClosedClassificationFieldValidated"
  "didRequireMissingPacketFailClosedValidation"
  "didRequireAmbiguousOwnerFailClosedValidation"
  "didRequireWrongThreadFailClosedValidation"
  "didRequireRendererCreatedSingletonFailClosedValidation"
  "didRequireThrowawaySingletonFailClosedValidation"
  "didRejectPointerHandleClassIdFieldValidation"
  "didRejectNativeObjectFieldValidation"
  "didRejectDiagnosticsOrArtifactFieldValidation"
  "didConfirmSourceReadinessTruthRecoveredFalse"
  "didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse"
  "didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse"
  "didConfirmProductionSingletonOwnershipTruthFalse"
  "didConfirmProductionSingletonImplementationBlocked"
  "didConfirmProductionActualAccessorCallSiteBlocked"
  "didKeepExternalPreexistingSingletonSourceWitnessPacketFieldValidationPreflightValueOnly"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: forbidden production application/visible/render token found" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" | grep -E '^\+' | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: witness_packet_field_validation_preflight_owner=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: witness_packet_recovery_preflight_before_field_validation_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: packet_version_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: external_owner_identity_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: preexisting_singleton_observed_before_renderer_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: main_thread_observation_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: source_lifetime_covers_runtime_admission_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: cleanup_ownership_retained_by_external_source_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: renderer_non_creation_invariant_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: renderer_non_accessor_invariant_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: headless_fail_closed_classification_field_validated=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: missing_packet_fail_closed_validation_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: ambiguous_owner_fail_closed_validation_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: wrong_thread_fail_closed_validation_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: renderer_created_singleton_fail_closed_validation_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: throwaway_singleton_fail_closed_validation_required=true"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: pointer_handle_class_id_field_validation_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: native_object_field_validation_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: diagnostics_or_artifact_field_validation_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: source_readiness_truth_recovered=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: external_preexisting_singleton_source_witness_truth=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: external_preexisting_singleton_source_readiness_truth=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: production_singleton_implementation_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: production_actual_accessor_call_site_allowed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: activation_policy_mutated=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: activation_called=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: appkit_event_loop_started=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: bounded_run_loop_pump_implemented=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: cleanup_teardown_executed=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: window_view_layer_created=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: visible_order=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: drawable_acquired=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: render_commit_present_gpu_submission=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: pointer_handle_class_id_return=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: artifact_or_diagnostics_publication=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication shared-application external preexisting singleton source witness packet field validation preflight owner probe: cjpm_toml_change=false"
