#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope renderer-state two-key handoff focused
# regression suite。它串联 owner probe、handoff packet、matrix 与 source/build
# guard。
# Truth: focused two-key handoff suite；不消费 D3 approval，不执行 runtime native
# probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-two-key-handoff-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_owner.sh"
HANDOFF_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_packet.sh"
MATRIX_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_matrix.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-owner.log"
HANDOFF_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff.log"
MATRIX_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-matrix.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$HANDOFF_LOG"
: > "$MATRIX_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$HANDOFF_PACKET_SCRIPT" "$MATRIX_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: log=$OWNER_LOG" >&2
  exit 5
fi

SHORT_HANDOFF_TMP="/tmp/cjgui-stage101-two-key-handoff-suite-${$}"
mkdir -p "$SHORT_HANDOFF_TMP"
if ! env TMPDIR="$SHORT_HANDOFF_TMP" zsh "$HANDOFF_PACKET_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: handoff packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: log=$HANDOFF_LOG" >&2
  exit 6
fi
handoff_packet="$(grep -Eo 'two_key_handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing handoff packet $handoff_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-matrix" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TWO_KEY_HANDOFF_PACKET="$handoff_packet" zsh "$MATRIX_SCRIPT" > "$MATRIX_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: matrix failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: log=$MATRIX_LOG" >&2
  exit 8
fi
matrix_packet="$(grep -Eo 'two_key_handoff_matrix_packet_path=[^[:space:]]+' "$MATRIX_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$matrix_packet" || ! -f "$matrix_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing matrix packet $matrix_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TWO_KEY_HANDOFF_PACKET="$handoff_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: log=$SOURCE_BUILD_LOG" >&2
  exit 10
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing source/build packet $source_build_packet" >&2
  exit 11
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_owner_present=true"
  "write_decision_contract_input=true"
  "external_provenance_packet_slot_bound=true"
  "independent_write_decision_packet_slot_bound=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing owner fact $fact" >&2
    exit 12
  fi
done

required_handoff_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
  "two_key_handoff_carrier_ready=true"
  "two_key_handoff_ready_for_external_shell=true"
  "renderer_state_write_after_two_key_handoff_allowed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing handoff fact $fact" >&2
    exit 13
  fi
done

required_matrix_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
  "synthetic_both_key_case_admitted=false"
  "external_shell_real_both_key_case_requires_separate_admission=true"
  "renderer_state_write_after_two_key_handoff_allowed=false"
)
for fact in "${required_matrix_facts[@]}"; do
  if ! grep -F "$fact" "$matrix_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing matrix fact $fact" >&2
    exit 14
  fi
done

required_source_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_owner_probe_passed=true"
  "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
  "d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
  "runtime_package_build_passed=true"
  "source_build_two_key_handoff_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: missing source/build fact $fact" >&2
    exit 15
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: protected path modified" >&2
  exit 16
fi

{
  echo "d3_result_envelope_renderer_state_two_key_handoff_suite_version=1"
  echo "d3_result_envelope_renderer_state_two_key_handoff_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
  echo "handoff_log=$HANDOFF_LOG"
  echo "two_key_handoff_packet=$handoff_packet"
  echo "d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
  echo "matrix_log=$MATRIX_LOG"
  echo "two_key_handoff_matrix_packet=$matrix_packet"
  echo "source_build_two_key_handoff_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_renderer_state_two_key_handoff_suite_passed=true"
  echo "two_key_handoff_carrier_ready=true"
  echo "two_key_handoff_ready_for_external_shell=true"
  echo "synthetic_both_key_case_admitted=false"
  echo "renderer_state_write_after_two_key_handoff_allowed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: route_classification=d3_result_envelope_renderer_state_two_key_handoff_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: d3_result_envelope_renderer_state_two_key_handoff_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: source_build_two_key_handoff_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two_key_handoff_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: d3_result_envelope_renderer_state_two_key_handoff_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff suite: human_approved_d3_execution_consumed=false"
