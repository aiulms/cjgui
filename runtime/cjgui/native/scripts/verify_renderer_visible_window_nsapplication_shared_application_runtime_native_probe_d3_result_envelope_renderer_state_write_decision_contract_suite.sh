#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope renderer-state write-decision contract
# focused regression suite。它串联 owner probe、contract packet、classifier、
# two-key join preflight 与 source/build guard。
# Truth: focused write-decision-contract suite；不消费 D3 approval，不执行 runtime
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-write-decision-contract-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_owner.sh"
CONTRACT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_classifier.sh"
TWO_KEY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-owner.log"
CONTRACT_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract.log"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-classifier.log"
TWO_KEY_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-two-key.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$CONTRACT_LOG"
: > "$CLASSIFIER_LOG"
: > "$TWO_KEY_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$CONTRACT_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$TWO_KEY_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: log=$OWNER_LOG" >&2
  exit 5
fi

SHORT_CONTRACT_TMP="/tmp/cjgui-stage100-write-contract-suite-${$}"
mkdir -p "$SHORT_CONTRACT_TMP"
if ! env TMPDIR="$SHORT_CONTRACT_TMP" zsh "$CONTRACT_PACKET_SCRIPT" > "$CONTRACT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: contract packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: log=$CONTRACT_LOG" >&2
  exit 6
fi
contract_packet="$(grep -Eo 'write_decision_contract_packet_path=[^[:space:]]+' "$CONTRACT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$contract_packet" || ! -f "$contract_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing contract packet $contract_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET="$contract_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: log=$CLASSIFIER_LOG" >&2
  exit 8
fi
classifier_packet="$(grep -Eo 'write_decision_contract_classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing classifier packet $classifier_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-two-key" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET="$contract_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_CLASSIFIER_PACKET="$classifier_packet" zsh "$TWO_KEY_SCRIPT" > "$TWO_KEY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: two-key join preflight failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: log=$TWO_KEY_LOG" >&2
  exit 10
fi
two_key_packet="$(grep -Eo 'two_key_join_packet_path=[^[:space:]]+' "$TWO_KEY_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$two_key_packet" || ! -f "$two_key_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing two-key packet $two_key_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET="$contract_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing source/build packet $source_build_packet" >&2
  exit 13
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_owner_present=true"
  "provenance_replay_input=true"
  "renderer_state_write_decision_contract_route_opened=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing owner fact $fact" >&2
    exit 14
  fi
done

required_contract_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "two_key_join_before_renderer_state_write_required=true"
  "current_shell_write_decision_admitted=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_contract_facts[@]}"; do
  if ! grep -F "$fact" "$contract_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing contract fact $fact" >&2
    exit 15
  fi
done

required_classifier_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  "write_decision_contract_is_independent=true"
  "two_key_renderer_state_write_join_ready=false"
  "renderer_state_write_permission_from_contract=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$classifier_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing classifier fact $fact" >&2
    exit 16
  fi
done

required_two_key_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
  "external_provenance_packet_key_required=true"
  "independent_write_decision_packet_key_required=true"
  "two_key_renderer_state_write_join_ready=false"
  "renderer_state_write_after_two_key_join_allowed=false"
)
for fact in "${required_two_key_facts[@]}"; do
  if ! grep -F "$fact" "$two_key_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing two-key fact $fact" >&2
    exit 17
  fi
done

required_source_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_owner_probe_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
  "runtime_package_build_passed=true"
  "source_build_write_decision_contract_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: missing source/build fact $fact" >&2
    exit 18
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: protected path modified" >&2
  exit 19
fi

{
  echo "d3_result_envelope_renderer_state_write_decision_contract_suite_version=1"
  echo "d3_result_envelope_renderer_state_write_decision_contract_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  echo "contract_log=$CONTRACT_LOG"
  echo "write_decision_contract_packet=$contract_packet"
  echo "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "write_decision_contract_classifier_packet=$classifier_packet"
  echo "d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
  echo "two_key_log=$TWO_KEY_LOG"
  echo "two_key_join_packet=$two_key_packet"
  echo "source_build_write_decision_contract_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_renderer_state_write_decision_contract_suite_passed=true"
  echo "renderer_state_write_decision_contract_ready=true"
  echo "write_decision_contract_is_independent=true"
  echo "external_provenance_packet_key_required=true"
  echo "independent_write_decision_packet_key_required=true"
  echo "two_key_renderer_state_write_join_ready=false"
  echo "renderer_state_write_after_two_key_join_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
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
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: route_classification=d3_result_envelope_renderer_state_write_decision_contract_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: d3_result_envelope_renderer_state_write_decision_contract_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: source_build_write_decision_contract_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write_decision_contract_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: d3_result_envelope_renderer_state_write_decision_contract_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract suite: human_approved_d3_execution_consumed=false"
