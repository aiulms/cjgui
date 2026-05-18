#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 D3 result-envelope admission fixture packet。它复用
# stage94 D3 environment recovery suite packet，并构造 current-shell pending packet
# 与 future external result schema packet，供 admission classifier 验证。
# Truth: result-envelope schema fixture；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-fixture"
RECOVERY_SUITE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_suite.sh"
RECOVERY_LOG="$TMP_DIR/d3-environment-recovery-suite.log"
CURRENT_PACKET="$TMP_DIR/d3-result-envelope-current-shell.packet"
FUTURE_PACKET="$TMP_DIR/d3-result-envelope-future-external-schema.packet"
FIXTURE_PACKET="$TMP_DIR/d3-result-envelope-fixture.packet"
EXTERNAL_RECOVERY_SUITE_PACKET="${CJGUI_D3_ENVIRONMENT_RECOVERY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$RECOVERY_LOG"
: > "$CURRENT_PACKET"
: > "$FUTURE_PACKET"
: > "$FIXTURE_PACKET"

if [[ ! -x "$RECOVERY_SUITE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: missing executable recovery suite $RECOVERY_SUITE" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: current fixture route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_RECOVERY_SUITE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_RECOVERY_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: external recovery suite packet missing $EXTERNAL_RECOVERY_SUITE_PACKET" >&2
    exit 5
  fi
  {
    echo "external_recovery_suite_packet_used=true"
    echo "suite_packet_path=$EXTERNAL_RECOVERY_SUITE_PACKET"
    cat "$EXTERNAL_RECOVERY_SUITE_PACKET"
  } > "$RECOVERY_LOG"
else
  if ! (
    unset CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED
    env TMPDIR="$TMP_DIR/nested-recovery-suite" zsh "$RECOVERY_SUITE"
  ) > "$RECOVERY_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: recovery suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: log=$RECOVERY_LOG" >&2
    exit 6
  fi
fi

required_recovery_facts=(
  "d3_environment_recovery_suite_passed=true"
  "bounded_native_fail_closed_packet_ready=true"
  "d3_environment_recovery_classifier_passed=true"
  "source_build_recovery_guard_passed=true"
  "runtime_package_build_passed=true"
  "failure_domain=automation_environment"
  "code_failure_domain=false"
  "external_metal_capable_shell_required=true"
  "metal_capable_shell_observed=false"
  "d3_limited_approval_available_but_unconsumed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_recovery_facts[@]}"; do
  if ! grep -F "$fact" "$RECOVERY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: missing recovery fact $fact" >&2
    exit 7
  fi
done

recovery_suite_packet="${EXTERNAL_RECOVERY_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$RECOVERY_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$recovery_suite_packet" || ! -f "$recovery_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: missing recovery suite packet $recovery_suite_packet" >&2
  exit 8
fi

for fact in "${required_recovery_facts[@]}"; do
  if ! grep -F "$fact" "$recovery_suite_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: missing recovery packet fact $fact" >&2
    exit 9
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: protected path modified" >&2
  exit 10
fi

{
  echo "d3_result_envelope_current_shell_packet_version=1"
  echo "upstream_d3_environment_recovery_suite_packet=$recovery_suite_packet"
  echo "result_envelope_context=current_shell_environment_blocked"
  echo "current_shell_result_envelope_accepted=false"
  echo "current_shell_admission_pending_external_packet=true"
  echo "external_metal_capable_shell_packet_required=true"
  echo "external_approval_consumption_proof_required=true"
  echo "capability_packet_before_result_envelope_required=true"
  echo "native_result_packet_schema_required=true"
  echo "integer_classification_only_required=true"
  echo "side_effect_classification_required=true"
  echo "artifact_containment_proof_required=true"
  echo "no_pointer_or_native_object_payload_required=true"
  echo "no_production_truth_upgrade_required=true"
  echo "failure_domain=automation_environment"
  echo "code_failure_domain=false"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$CURRENT_PACKET"

{
  echo "d3_result_envelope_future_external_schema_version=1"
  echo "result_envelope_context=future_external_metal_capable_shell"
  echo "future_external_result_envelope_schema_admitted=true"
  echo "future_external_runtime_native_probe_execution_schema_only=true"
  echo "required_external_metal_capable_shell_packet=true"
  echo "required_external_approval_consumption_proof=true"
  echo "required_native_result_packet_schema=true"
  echo "required_integer_classification_only=true"
  echo "required_side_effect_classification=true"
  echo "required_artifact_containment_proof=true"
  echo "required_no_pointer_or_native_object_payload=true"
  echo "required_no_production_truth_upgrade=true"
  echo "allowed_success_classification_values=240_or_241"
  echo "allowed_failure_classification_family=fail_closed"
  echo "allowed_success_side_effect_classifications=called_preexisting_singleton_no_creation_or_throwaway_singleton_created_by_accessor"
  echo "production_singleton_ownership_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$FUTURE_PACKET"

{
  echo "d3_result_envelope_fixture_version=1"
  echo "d3_environment_recovery_suite_packet=$recovery_suite_packet"
  echo "current_shell_packet=$CURRENT_PACKET"
  echo "future_external_schema_packet=$FUTURE_PACKET"
  echo "result_envelope_schema_fixture_ready=true"
  echo "current_shell_result_envelope_accepted=false"
  echo "current_shell_admission_pending_external_packet=true"
  echo "future_external_result_envelope_schema_admitted=true"
  echo "external_metal_capable_shell_packet_required=true"
  echo "external_approval_consumption_proof_required=true"
  echo "capability_packet_before_result_envelope_required=true"
  echo "native_result_packet_schema_required=true"
  echo "integer_classification_only_required=true"
  echo "side_effect_classification_required=true"
  echo "artifact_containment_proof_required=true"
  echo "no_pointer_or_native_object_payload_required=true"
  echo "no_production_truth_upgrade_required=true"
  echo "failure_domain=automation_environment"
  echo "code_failure_domain=false"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$FIXTURE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: route_classification=d3_result_envelope_fixture"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: result_envelope_schema_fixture_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: fixture_packet_path=$FIXTURE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: current_shell_packet=$CURRENT_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: future_external_schema_packet=$FUTURE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: d3_environment_recovery_suite_packet=$recovery_suite_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: current_shell_result_envelope_accepted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: current_shell_admission_pending_external_packet=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: future_external_result_envelope_schema_admitted=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: external_metal_capable_shell_packet_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: external_approval_consumption_proof_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: capability_packet_before_result_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: native_result_packet_schema_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: integer_classification_only_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: side_effect_classification_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: artifact_containment_proof_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: no_pointer_or_native_object_payload_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: no_production_truth_upgrade_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope fixture: human_approved_d3_execution_consumed=false"
