#!/usr/bin/env zsh
#
# 维护注释：本脚本从 suite packet audit 结果回放 handoff packet，并确认 rerun
# packet、source/build packet 和 handoff packet 的 next actor / shell / stop-line 一致。
# Truth: handoff replay contract / blocker recovery route；不执行 runtime native probe，
# 不消费 D3 approval，不调用 application accessor，不创建 singleton，不扩 native
# bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-handoff-replay"
SUITE_PACKET_AUDIT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_suite_packet_audit.sh"
AUDIT_LOG="$TMP_DIR/suite-packet-audit.log"
HANDOFF_REPLAY_PACKET="$TMP_DIR/explicit-approval-handoff-replay-contract.packet"
EXTERNAL_AUDIT_PACKET="${CJGUI_EXPLICIT_APPROVAL_SUITE_AUDIT_PACKET:-}"
EXTERNAL_SUITE_PACKET="${CJGUI_EXPLICIT_APPROVAL_REPLAY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$AUDIT_LOG"
: > "$HANDOFF_REPLAY_PACKET"

if [[ ! -x "$SUITE_PACKET_AUDIT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: missing executable suite packet audit $SUITE_PACKET_AUDIT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_AUDIT_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_AUDIT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: external audit packet missing $EXTERNAL_AUDIT_PACKET" >&2
    exit 5
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: external_audit_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_suite_packet_audit"
    echo "audit_packet_path=$EXTERNAL_AUDIT_PACKET"
    cat "$EXTERNAL_AUDIT_PACKET"
  } > "$AUDIT_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-audit" CJGUI_EXPLICIT_APPROVAL_REPLAY_SUITE_PACKET="$EXTERNAL_SUITE_PACKET" zsh "$SUITE_PACKET_AUDIT" > "$AUDIT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: suite packet audit failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: log=$AUDIT_LOG" >&2
    exit 6
  fi
fi

required_audit_facts=(
  "route_classification=runtime_native_probe_explicit_approval_suite_packet_audit"
  "suite_packet_audit_passed=true"
  "nested_packet_paths_reachable=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_audit_facts[@]}"; do
  if ! grep -F "$fact" "$AUDIT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: missing audit fact $fact" >&2
    exit 7
  fi
done

audit_packet="${EXTERNAL_AUDIT_PACKET:-$(grep -Eo 'audit_packet_path=[^[:space:]]+' "$AUDIT_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$audit_packet" || ! -f "$audit_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: missing audit packet $audit_packet" >&2
  exit 8
fi

handoff_packet="$(grep -Eo '^handoff_packet=[^[:space:]]+' "$audit_packet" | tail -1 | cut -d= -f2-)"
rerun_packet="$(grep -Eo '^rerun_packet=[^[:space:]]+' "$audit_packet" | tail -1 | cut -d= -f2-)"
source_build_packet="$(grep -Eo '^source_build_packet=[^[:space:]]+' "$audit_packet" | tail -1 | cut -d= -f2-)"
for packet in "$handoff_packet" "$rerun_packet" "$source_build_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: missing nested packet $packet" >&2
    exit 9
  fi
done

for packet in "$handoff_packet" "$rerun_packet" "$source_build_packet"; do
  for fact in \
    "required_next_actor=human_operator" \
    "required_shell=explicitly_approved_shell" \
    "code_failure_domain=false" \
    "runtime_native_probe_execution=false" \
    "human_approved_d3_execution_consumed=false" \
    "application_singleton_accessor_call=false" \
    "native_bridge_expansion=false" \
    "production_public_c_abi_added=false" \
    "renderer_state_write=false"; do
    if ! grep -F "$fact" "$packet" >/dev/null 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: missing nested fact $fact in $packet" >&2
      exit 10
    fi
  done
done

if ! grep -F "handoff_packet_ready=true" "$handoff_packet" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: handoff packet not ready" >&2
  exit 11
fi
if ! grep -F "two_pass_mesh_rerun_contract_passed=true" "$rerun_packet" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: rerun packet not ready" >&2
  exit 12
fi
if ! grep -F "source_build_guard_passed=true" "$source_build_packet" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: source/build packet not ready" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: protected path modified" >&2
  exit 14
fi

{
  echo "explicit_approval_handoff_replay_contract_version=1"
  echo "handoff_replay_contract_passed=true"
  echo "external_audit_packet_used=$([[ -n "$EXTERNAL_AUDIT_PACKET" ]] && echo true || echo false)"
  echo "audit_log=$AUDIT_LOG"
  echo "audit_packet=$audit_packet"
  echo "handoff_packet=$handoff_packet"
  echo "rerun_packet=$rerun_packet"
  echo "source_build_packet=$source_build_packet"
  echo "nested_packet_stop_lines_consistent=true"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "approved_runtime_native_probe_execution_admitted=false"
  echo "metal_capable_shell_does_not_imply_approval=true"
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
} > "$HANDOFF_REPLAY_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: route_classification=runtime_native_probe_explicit_approval_handoff_replay_contract"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: handoff_replay_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: handoff_replay_packet_path=$HANDOFF_REPLAY_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: audit_packet=$audit_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: nested_packet_stop_lines_consistent=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff replay contract: renderer_state_write=false"
