#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 external packet provenance replay suite packet，并生成
# independent renderer-state write-decision contract packet。它只固定 future
# two-key write admission contract，不产出 external result packet，不写 renderer
# state。
# Truth: renderer-state write-decision contract packet；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩
# native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-write-decision-contract-packet"
PROVENANCE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_suite.sh"
PROVENANCE_SUITE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-suite.log"
WRITE_DECISION_CONTRACT_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract.packet"
EXTERNAL_PROVENANCE_SUITE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_SUITE_PACKET:-}"
RUNTIME_STATE_FILE="$ROOT_DIR/src/runtime_state.cj"

mkdir -p "$TMP_DIR"
: > "$PROVENANCE_SUITE_LOG"
: > "$WRITE_DECISION_CONTRACT_PACKET"

if [[ ! -x "$PROVENANCE_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: missing executable script $PROVENANCE_SUITE_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: current packet route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_PROVENANCE_SUITE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PROVENANCE_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: external provenance suite packet missing $EXTERNAL_PROVENANCE_SUITE_PACKET" >&2
    exit 5
  fi
  {
    echo "external_provenance_replay_suite_packet_used=true"
    echo "suite_packet_path=$EXTERNAL_PROVENANCE_SUITE_PACKET"
    cat "$EXTERNAL_PROVENANCE_SUITE_PACKET"
  } > "$PROVENANCE_SUITE_LOG"
else
  SHORT_SUITE_TMP="/tmp/cjgui-stage100-write-contract-suite-${$}"
  mkdir -p "$SHORT_SUITE_TMP"
  if ! env TMPDIR="$SHORT_SUITE_TMP" zsh "$PROVENANCE_SUITE_SCRIPT" > "$PROVENANCE_SUITE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: provenance replay suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: log=$PROVENANCE_SUITE_LOG" >&2
    exit 6
  fi
fi

provenance_suite_packet="${EXTERNAL_PROVENANCE_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$PROVENANCE_SUITE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$provenance_suite_packet" || ! -f "$provenance_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: missing provenance suite packet $provenance_suite_packet" >&2
  exit 7
fi

required_provenance_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_suite_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  "external_packet_provenance_replay_ready=true"
  "current_shell_provenance_replay_admitted=false"
  "external_packet_provenance_replay_allowed=false"
  "shape_admission_is_not_provenance_truth=true"
  "separate_renderer_state_write_decision_required=true"
  "renderer_state_write_after_provenance_replay_allowed=false"
  "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_provenance_facts[@]}"; do
  if ! grep -F "$fact" "$provenance_suite_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: missing provenance suite fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: protected path modified" >&2
  exit 9
fi

runtime_state_line_count="$(wc -l < "$RUNTIME_STATE_FILE" | tr -d '[:space:]')"
if [[ "$runtime_state_line_count" != "10065" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: unexpected runtime_state.cj line count $runtime_state_line_count" >&2
  exit 10
fi

{
  echo "d3_result_envelope_renderer_state_write_decision_contract_packet_version=1"
  echo "provenance_replay_suite_packet=$provenance_suite_packet"
  echo "provenance_replay_input_consumed=true"
  echo "renderer_state_write_decision_contract_ready=true"
  echo "external_provenance_replay_before_write_decision_required=true"
  echo "independent_renderer_state_write_decision_packet_required=true"
  echo "two_key_join_before_renderer_state_write_required=true"
  echo "current_shell_write_decision_admission_denied=true"
  echo "current_shell_write_decision_admitted=false"
  echo "write_decision_contract_dehydrated=true"
  echo "external_provenance_packet_absent_in_current_shell=true"
  echo "external_packet_provenance_replay_allowed=false"
  echo "provenance_replay_is_not_write_permission=true"
  echo "renderer_state_write_after_write_decision_contract_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
  echo "runtime_state_line_count=$runtime_state_line_count"
  echo "runtime_state_line_count_invariant=true"
  echo "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
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
} > "$WRITE_DECISION_CONTRACT_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: route_classification=d3_result_envelope_renderer_state_write_decision_contract_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: write_decision_contract_packet_path=$WRITE_DECISION_CONTRACT_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: provenance_replay_suite_packet=$provenance_suite_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: current_shell_write_decision_admitted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: two_key_join_before_renderer_state_write_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract packet: human_approved_d3_execution_consumed=false"
