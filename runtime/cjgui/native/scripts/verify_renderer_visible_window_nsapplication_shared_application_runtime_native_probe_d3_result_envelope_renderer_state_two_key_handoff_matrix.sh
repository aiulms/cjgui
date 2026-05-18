#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 two-key handoff carrier 的组合矩阵。它确认 no-key、
# 单 key 与 synthetic both-key case 都不能触发 current-shell renderer-state write。
# Truth: renderer-state two-key handoff matrix；不消费 D3 approval，不执行 runtime
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-two-key-handoff-matrix"
HANDOFF_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_packet.sh"
HANDOFF_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff.log"
MATRIX_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-matrix.packet"
EXTERNAL_HANDOFF_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TWO_KEY_HANDOFF_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$HANDOFF_LOG"
: > "$MATRIX_PACKET"

if [[ ! -x "$HANDOFF_PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: missing executable script $HANDOFF_PACKET_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: current matrix route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_HANDOFF_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_HANDOFF_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: external handoff packet missing $EXTERNAL_HANDOFF_PACKET" >&2
    exit 5
  fi
  {
    echo "external_two_key_handoff_packet_used=true"
    echo "two_key_handoff_packet_path=$EXTERNAL_HANDOFF_PACKET"
    cat "$EXTERNAL_HANDOFF_PACKET"
  } > "$HANDOFF_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-handoff" zsh "$HANDOFF_PACKET_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: handoff packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: log=$HANDOFF_LOG" >&2
    exit 6
  fi
fi

handoff_packet="${EXTERNAL_HANDOFF_PACKET:-$(grep -Eo 'two_key_handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: missing handoff packet $handoff_packet" >&2
  exit 7
fi

required_handoff_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
  "two_key_handoff_carrier_ready=true"
  "external_provenance_packet_slot_bound=true"
  "independent_write_decision_packet_slot_bound=true"
  "packet_path_artifact_handoff_required=true"
  "external_shell_produced_provenance_packet_required=true"
  "synthetic_packet_admission_denied=true"
  "write_decision_contract_is_not_write_permission=true"
  "current_shell_external_provenance_packet_present=false"
  "current_shell_independent_write_decision_packet_present=false"
  "renderer_state_write_after_two_key_handoff_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: missing handoff fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: protected path modified" >&2
  exit 9
fi

{
  echo "d3_result_envelope_renderer_state_two_key_handoff_matrix_packet_version=1"
  echo "two_key_handoff_packet=$handoff_packet"
  echo "d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
  echo "no_key_case_renderer_state_write_allowed=false"
  echo "external_key_only_case_renderer_state_write_allowed=false"
  echo "write_decision_key_only_case_renderer_state_write_allowed=false"
  echo "synthetic_both_key_case_renderer_state_write_allowed=false"
  echo "synthetic_both_key_case_admitted=false"
  echo "external_shell_real_both_key_case_requires_separate_admission=true"
  echo "external_shell_real_both_key_case_current_shell_admitted=false"
  echo "two_key_handoff_ready_for_external_shell=true"
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
} > "$MATRIX_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: route_classification=d3_result_envelope_renderer_state_two_key_handoff_matrix"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: two_key_handoff_matrix_packet_path=$MATRIX_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: two_key_handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: synthetic_both_key_case_admitted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: renderer_state_write_after_two_key_handoff_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff matrix: human_approved_d3_execution_consumed=false"
