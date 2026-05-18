#!/usr/bin/env zsh
#
# 维护注释：本脚本把 stage92 replay audit suite 输出收束为 checkpoint packet。
# 默认执行 bounded replay audit suite；调用方也可以传入已有
# CJGUI_EXPLICIT_APPROVAL_REPLAY_AUDIT_SUITE_PACKET 复用证据。
# Truth: script-managed evidence / rerun checkpoint packet；不执行 runtime native
# probe，不消费 D3 approval，不调用 application accessor，不创建 singleton，不扩
# native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-replay-checkpoint-packet"
REPLAY_AUDIT_SUITE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_audit_suite.sh"
SUITE_LOG="$TMP_DIR/replay-audit-suite.log"
CHECKPOINT_PACKET="$TMP_DIR/explicit-approval-replay-checkpoint.packet"
EXTERNAL_REPLAY_AUDIT_SUITE_PACKET="${CJGUI_EXPLICIT_APPROVAL_REPLAY_AUDIT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$SUITE_LOG"
: > "$CHECKPOINT_PACKET"

if [[ ! -x "$REPLAY_AUDIT_SUITE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: missing executable replay audit suite $REPLAY_AUDIT_SUITE" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

external_replay_audit_suite_packet_used=false
if [[ -n "$EXTERNAL_REPLAY_AUDIT_SUITE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_REPLAY_AUDIT_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: external suite packet missing $EXTERNAL_REPLAY_AUDIT_SUITE_PACKET" >&2
    exit 5
  fi
  external_replay_audit_suite_packet_used=true
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: external_replay_audit_suite_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_replay_audit_suite"
    echo "replay_audit_suite_packet_path=$EXTERNAL_REPLAY_AUDIT_SUITE_PACKET"
    cat "$EXTERNAL_REPLAY_AUDIT_SUITE_PACKET"
  } > "$SUITE_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-suite" zsh "$REPLAY_AUDIT_SUITE" > "$SUITE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: replay audit suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: log=$SUITE_LOG" >&2
    exit 6
  fi
fi

required_suite_facts=(
  "route_classification=runtime_native_probe_explicit_approval_replay_audit_suite"
  "replay_audit_owner_probe_passed=true"
  "suite_packet_audit_passed=true"
  "handoff_replay_contract_passed=true"
  "source_build_replay_guard_passed=true"
  "explicit_approval_replay_audit_suite_passed=true"
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
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$SUITE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: missing suite fact $fact" >&2
    exit 7
  fi
done

replay_audit_suite_packet="${EXTERNAL_REPLAY_AUDIT_SUITE_PACKET:-$(grep -Eo 'replay_audit_suite_packet_path=[^[:space:]]+' "$SUITE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$replay_audit_suite_packet" || ! -f "$replay_audit_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: missing replay audit suite packet $replay_audit_suite_packet" >&2
  exit 8
fi

required_packet_facts=(
  "explicit_approval_replay_audit_suite_version=1"
  "replay_audit_owner_probe_passed=true"
  "suite_packet_audit_passed=true"
  "handoff_replay_contract_passed=true"
  "source_build_replay_guard_passed=true"
  "explicit_approval_replay_audit_suite_passed=true"
  "approved_runtime_native_probe_execution_admitted=false"
  "metal_capable_shell_does_not_imply_approval=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
)
for fact in "${required_packet_facts[@]}"; do
  if ! grep -F "$fact" "$replay_audit_suite_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: missing replay audit packet fact $fact" >&2
    exit 9
  fi
done

audit_packet="$(grep -Eo '^audit_packet=[^[:space:]]+' "$replay_audit_suite_packet" | tail -1 | cut -d= -f2-)"
handoff_replay_packet="$(grep -Eo '^handoff_replay_packet=[^[:space:]]+' "$replay_audit_suite_packet" | tail -1 | cut -d= -f2-)"
source_build_replay_packet="$(grep -Eo '^source_build_replay_packet=[^[:space:]]+' "$replay_audit_suite_packet" | tail -1 | cut -d= -f2-)"
for packet in "$audit_packet" "$handoff_replay_packet" "$source_build_replay_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: missing nested packet $packet" >&2
    exit 10
  fi
done

if ! grep -F "suite_packet_audit_passed=true" "$audit_packet" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: audit packet not ready" >&2
  exit 11
fi
if ! grep -F "handoff_replay_contract_passed=true" "$handoff_replay_packet" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: handoff replay packet not ready" >&2
  exit 12
fi
if ! grep -F "source_build_replay_guard_passed=true" "$source_build_replay_packet" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: source/build replay packet not ready" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: protected path modified" >&2
  exit 14
fi

{
  echo "explicit_approval_replay_checkpoint_packet_version=1"
  echo "replay_checkpoint_packet_ready=true"
  echo "replay_audit_suite_packet=$replay_audit_suite_packet"
  echo "external_replay_audit_suite_packet_used=$external_replay_audit_suite_packet_used"
  echo "suite_log=$SUITE_LOG"
  echo "audit_packet=$audit_packet"
  echo "handoff_replay_packet=$handoff_replay_packet"
  echo "source_build_replay_packet=$source_build_replay_packet"
  echo "bounded_replay_audit_suite_passed=true"
  echo "checkpoint_packet_reuse_contract_passed=true"
  echo "nested_checkpoint_packets_reachable=true"
  echo "failure_domain_classifier_required=true"
  echo "source_build_checkpoint_guard_required=true"
  echo "focused_checkpoint_suite_required=true"
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
} > "$CHECKPOINT_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: route_classification=runtime_native_probe_explicit_approval_replay_checkpoint_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: replay_checkpoint_packet_ready=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: checkpoint_packet_path=$CHECKPOINT_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: replay_audit_suite_packet=$replay_audit_suite_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: external_replay_audit_suite_packet_used=$external_replay_audit_suite_packet_used"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: bounded_replay_audit_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: checkpoint_packet_reuse_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: nested_checkpoint_packets_reachable=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: audit_packet=$audit_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: handoff_replay_packet=$handoff_replay_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: source_build_replay_packet=$source_build_replay_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint packet: renderer_state_write=false"
