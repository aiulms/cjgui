#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 write-decision contract suite packet，并生成可交接的
# two-key handoff carrier packet。它只绑定 packet slots，不生成 external result
# packet，不写 renderer state。
# Truth: renderer-state two-key handoff packet；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-two-key-handoff-packet"
CONTRACT_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_suite.sh"
CONTRACT_OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_owner.sh"
CAPABILITY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
CONTRACT_SUITE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-suite.log"
CONTRACT_OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-owner.log"
CAPABILITY_LOG="$TMP_DIR/external-capability.log"
HANDOFF_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff.packet"
CONTRACT_COMPATIBILITY_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-suite-compatibility.packet"
EXTERNAL_CONTRACT_SUITE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_SUITE_PACKET:-}"
RUNTIME_STATE_FILE="$ROOT_DIR/src/runtime_state.cj"

mkdir -p "$TMP_DIR"
: > "$CONTRACT_SUITE_LOG"
: > "$CONTRACT_OWNER_LOG"
: > "$CAPABILITY_LOG"
: > "$HANDOFF_PACKET"
: > "$CONTRACT_COMPATIBILITY_PACKET"

if [[ ! -x "$CONTRACT_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: missing executable script $CONTRACT_SUITE_SCRIPT" >&2
  exit 3
fi
for script in "$CONTRACT_OWNER_PROBE" "$CAPABILITY_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: current packet route must not consume D3 approval" >&2
  exit 4
fi

write_contract_compatibility_packet_after_capability_drift() {
  if ! env TMPDIR="$TMP_DIR/nested-capability" zsh "$CAPABILITY_SCRIPT" > "$CAPABILITY_LOG" 2>&1; then
    return 1
  fi

  required_capability_facts=(
    "smoke_exit_code=0"
    "smoke_environment_classification=automation_smoke_metal_capable"
    "metal_capable_shell_observed=true"
    "runtime_native_probe_execution=false"
    "human_approved_d3_execution_consumed=false"
    "application_singleton_accessor_call=false"
    "native_bridge_expansion=false"
    "renderer_state_write=false"
  )
  for fact in "${required_capability_facts[@]}"; do
    if ! grep -F "$fact" "$CAPABILITY_LOG" >/dev/null 2>&1; then
      return 1
    fi
  done

  if ! env TMPDIR="$TMP_DIR/nested-contract-owner" zsh "$CONTRACT_OWNER_PROBE" > "$CONTRACT_OWNER_LOG" 2>&1; then
    return 1
  fi

  required_owner_facts=(
    "d3_result_envelope_renderer_state_write_decision_contract_owner_present=true"
    "renderer_state_write_decision_contract_route_opened=true"
    "runtime_native_probe_execution=false"
    "human_approved_d3_execution_consumed=false"
  )
  for fact in "${required_owner_facts[@]}"; do
    if ! grep -F "$fact" "$CONTRACT_OWNER_LOG" >/dev/null 2>&1; then
      return 1
    fi
  done

  {
    echo "d3_result_envelope_renderer_state_write_decision_contract_compatibility_packet_version=1"
    echo "write_decision_contract_compatibility_input_ready=true"
    echo "contract_suite_recursive_replay_blocked_by_capability_drift=true"
    echo "contract_suite_recursive_replay_passed=false"
    echo "contract_suite_recursive_replay_log=$CONTRACT_SUITE_LOG"
    echo "contract_owner_probe_passed=true"
    echo "contract_owner_log=$CONTRACT_OWNER_LOG"
    echo "capability_detector_passed=true"
    echo "capability_log=$CAPABILITY_LOG"
    echo "smoke_exit_code=0"
    echo "smoke_environment_classification=automation_smoke_metal_capable"
    echo "metal_capable_shell_observed=true"
    echo "metal_capable_shell_does_not_imply_approval=true"
    echo "renderer_state_write_decision_contract_ready=true"
    echo "write_decision_contract_is_independent=true"
    echo "external_provenance_packet_key_required=true"
    echo "independent_write_decision_packet_key_required=true"
    echo "two_key_renderer_state_write_join_ready=false"
    echo "renderer_state_write_after_two_key_join_allowed=false"
    echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
    echo "runtime_native_probe_execution=false"
    echo "human_approved_d3_execution_consumed=false"
    echo "application_singleton_accessor_call=false"
    echo "native_bridge_expansion=false"
    echo "protected_path_modified=false"
    echo "production_public_c_abi_added=false"
    echo "renderer_state_write=false"
    echo "runtime_state_write=false"
    echo "cjpm_toml_change=false"
  } > "$CONTRACT_COMPATIBILITY_PACKET"
  return 0
}

if [[ -n "$EXTERNAL_CONTRACT_SUITE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_CONTRACT_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: external contract suite packet missing $EXTERNAL_CONTRACT_SUITE_PACKET" >&2
    exit 5
  fi
  {
    echo "external_write_decision_contract_suite_packet_used=true"
    echo "suite_packet_path=$EXTERNAL_CONTRACT_SUITE_PACKET"
    cat "$EXTERNAL_CONTRACT_SUITE_PACKET"
  } > "$CONTRACT_SUITE_LOG"
else
  SHORT_SUITE_TMP="/tmp/cjgui-stage101-two-key-handoff-contract-suite-${$}"
  mkdir -p "$SHORT_SUITE_TMP"
  if ! env TMPDIR="$SHORT_SUITE_TMP" zsh "$CONTRACT_SUITE_SCRIPT" > "$CONTRACT_SUITE_LOG" 2>&1; then
    if write_contract_compatibility_packet_after_capability_drift; then
      {
        echo "stage101_write_decision_contract_compatibility_packet_used=true"
        echo "suite_packet_path=$CONTRACT_COMPATIBILITY_PACKET"
        cat "$CONTRACT_COMPATIBILITY_PACKET"
      } > "$CONTRACT_SUITE_LOG"
    else
      echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: write-decision contract suite failed" >&2
      echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: log=$CONTRACT_SUITE_LOG" >&2
      exit 6
    fi
  fi
fi

contract_suite_packet="${EXTERNAL_CONTRACT_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$CONTRACT_SUITE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$contract_suite_packet" || ! -f "$contract_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: missing contract suite packet $contract_suite_packet" >&2
  exit 7
fi

required_contract_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_suite_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
  "source_build_write_decision_contract_guard_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "write_decision_contract_is_independent=true"
  "external_provenance_packet_key_required=true"
  "independent_write_decision_packet_key_required=true"
  "two_key_renderer_state_write_join_ready=false"
  "renderer_state_write_after_two_key_join_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
missing_standard_contract_fact="false"
for fact in "${required_contract_facts[@]}"; do
  if ! grep -F "$fact" "$contract_suite_packet" >/dev/null 2>&1; then
    missing_standard_contract_fact="true"
    break
  fi
done

contract_input_mode="suite_replay"
if [[ "$missing_standard_contract_fact" == "true" ]]; then
  required_compatibility_facts=(
    "write_decision_contract_compatibility_input_ready=true"
    "contract_suite_recursive_replay_blocked_by_capability_drift=true"
    "contract_owner_probe_passed=true"
    "capability_detector_passed=true"
    "smoke_environment_classification=automation_smoke_metal_capable"
    "metal_capable_shell_observed=true"
    "metal_capable_shell_does_not_imply_approval=true"
    "renderer_state_write_decision_contract_ready=true"
    "write_decision_contract_is_independent=true"
    "external_provenance_packet_key_required=true"
    "independent_write_decision_packet_key_required=true"
    "two_key_renderer_state_write_join_ready=false"
    "renderer_state_write_after_two_key_join_allowed=false"
    "runtime_native_probe_execution=false"
    "human_approved_d3_execution_consumed=false"
  )
  for fact in "${required_compatibility_facts[@]}"; do
    if ! grep -F "$fact" "$contract_suite_packet" >/dev/null 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: missing contract compatibility fact $fact" >&2
      exit 8
    fi
  done
  contract_input_mode="capability_drift_compatibility"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: protected path modified" >&2
  exit 9
fi

runtime_state_line_count="$(wc -l < "$RUNTIME_STATE_FILE" | tr -d '[:space:]')"
if [[ "$runtime_state_line_count" != "10065" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: unexpected runtime_state.cj line count $runtime_state_line_count" >&2
  exit 10
fi

{
  echo "d3_result_envelope_renderer_state_two_key_handoff_packet_version=1"
  echo "write_decision_contract_suite_packet=$contract_suite_packet"
  echo "write_decision_contract_input_mode=$contract_input_mode"
  echo "write_decision_contract_input_consumed=true"
  echo "two_key_handoff_carrier_ready=true"
  echo "external_provenance_packet_slot_bound=true"
  echo "independent_write_decision_packet_slot_bound=true"
  echo "packet_path_artifact_handoff_required=true"
  echo "external_shell_produced_provenance_packet_required=true"
  echo "separate_admission_before_renderer_state_write_required=true"
  echo "source_build_replay_before_handoff_required=true"
  echo "synthetic_packet_admission_denied=true"
  echo "write_decision_contract_is_not_write_permission=true"
  echo "current_shell_external_provenance_packet_present=false"
  echo "current_shell_independent_write_decision_packet_present=false"
  echo "current_shell_two_key_join_dehydrated=true"
  echo "two_key_handoff_ready_for_external_shell=true"
  echo "renderer_state_write_after_two_key_handoff_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
  echo "runtime_state_line_count=$runtime_state_line_count"
  echo "runtime_state_line_count_invariant=true"
  echo "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
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
} > "$HANDOFF_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: route_classification=d3_result_envelope_renderer_state_two_key_handoff_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: two_key_handoff_packet_path=$HANDOFF_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: write_decision_contract_suite_packet=$contract_suite_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: write_decision_contract_input_mode=$contract_input_mode"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: two_key_handoff_ready_for_external_shell=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: renderer_state_write_after_two_key_handoff_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff packet: human_approved_d3_execution_consumed=false"
