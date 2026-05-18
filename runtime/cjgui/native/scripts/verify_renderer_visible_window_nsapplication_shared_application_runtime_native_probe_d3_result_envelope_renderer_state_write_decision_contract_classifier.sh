#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state write-decision contract packet，并把
# contract 分类为 independent future decision contract，而不是 current-shell
# write admission。
# Truth: write-decision contract classifier；不消费 D3 approval，不执行 runtime
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-write-decision-contract-classifier"
CONTRACT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_packet.sh"
CONTRACT_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-classifier.packet"
EXTERNAL_CONTRACT_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$CONTRACT_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$CONTRACT_PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: missing executable script $CONTRACT_PACKET_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: current classifier route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_CONTRACT_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_CONTRACT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: external contract packet missing $EXTERNAL_CONTRACT_PACKET" >&2
    exit 5
  fi
  {
    echo "external_write_decision_contract_packet_used=true"
    echo "write_decision_contract_packet_path=$EXTERNAL_CONTRACT_PACKET"
    cat "$EXTERNAL_CONTRACT_PACKET"
  } > "$CONTRACT_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-contract" zsh "$CONTRACT_PACKET_SCRIPT" > "$CONTRACT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: contract packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: log=$CONTRACT_LOG" >&2
    exit 6
  fi
fi

contract_packet="${EXTERNAL_CONTRACT_PACKET:-$(grep -Eo 'write_decision_contract_packet_path=[^[:space:]]+' "$CONTRACT_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$contract_packet" || ! -f "$contract_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: missing contract packet $contract_packet" >&2
  exit 7
fi

required_contract_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "external_provenance_replay_before_write_decision_required=true"
  "independent_renderer_state_write_decision_packet_required=true"
  "two_key_join_before_renderer_state_write_required=true"
  "current_shell_write_decision_admitted=false"
  "provenance_replay_is_not_write_permission=true"
  "renderer_state_write_after_write_decision_contract_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_contract_facts[@]}"; do
  if ! grep -F "$fact" "$contract_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: missing contract fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: protected path modified" >&2
  exit 9
fi

{
  echo "d3_result_envelope_renderer_state_write_decision_contract_classifier_packet_version=1"
  echo "write_decision_contract_packet=$contract_packet"
  echo "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  echo "write_decision_contract_shape_admitted=true"
  echo "write_decision_contract_is_independent=true"
  echo "write_decision_contract_is_not_current_shell_admission=true"
  echo "current_shell_write_decision_admitted=false"
  echo "external_packet_provenance_replay_allowed=false"
  echo "external_provenance_packet_required_for_write_join=true"
  echo "independent_write_decision_packet_required_for_write_join=true"
  echo "two_key_renderer_state_write_join_ready=false"
  echo "renderer_state_write_permission_from_contract=false"
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
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: route_classification=d3_result_envelope_renderer_state_write_decision_contract_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: write_decision_contract_classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: write_decision_contract_packet=$contract_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: two_key_renderer_state_write_join_ready=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: renderer_state_write_permission_from_contract=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract classifier: human_approved_d3_execution_consumed=false"
