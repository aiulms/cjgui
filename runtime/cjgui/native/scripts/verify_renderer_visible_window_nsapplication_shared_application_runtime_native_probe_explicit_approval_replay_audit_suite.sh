#!/usr/bin/env zsh
#
# 维护注释：本脚本是 explicit approval replay audit focused regression suite。
# 它串联 owner probe、suite packet audit、handoff replay contract 与 source/build
# replay guard。
# Truth: probe orchestration runner / focused regression suite；不执行 runtime native
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-replay-audit-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_audit_owner.sh"
SUITE_PACKET_AUDIT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_suite_packet_audit.sh"
HANDOFF_REPLAY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_replay_contract.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/replay-audit-owner.log"
AUDIT_LOG="$TMP_DIR/suite-packet-audit.log"
HANDOFF_LOG="$TMP_DIR/handoff-replay-contract.log"
SOURCE_BUILD_LOG="$TMP_DIR/replay-source-build-guard.log"
SUITE_PACKET="$TMP_DIR/explicit-approval-replay-audit-suite.packet"
EXTERNAL_STAGE91_SUITE_PACKET="${CJGUI_EXPLICIT_APPROVAL_REPLAY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$AUDIT_LOG"
: > "$HANDOFF_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$SUITE_PACKET_AUDIT" "$HANDOFF_REPLAY" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-audit" CJGUI_EXPLICIT_APPROVAL_REPLAY_SUITE_PACKET="$EXTERNAL_STAGE91_SUITE_PACKET" zsh "$SUITE_PACKET_AUDIT" > "$AUDIT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: suite packet audit failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: log=$AUDIT_LOG" >&2
  exit 6
fi

audit_packet="$(grep -Eo 'audit_packet_path=[^[:space:]]+' "$AUDIT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$audit_packet" || ! -f "$audit_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing audit packet $audit_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-handoff" CJGUI_EXPLICIT_APPROVAL_SUITE_AUDIT_PACKET="$audit_packet" zsh "$HANDOFF_REPLAY" > "$HANDOFF_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: handoff replay contract failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: log=$HANDOFF_LOG" >&2
  exit 8
fi
if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_EXPLICIT_APPROVAL_SUITE_AUDIT_PACKET="$audit_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: source build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: log=$SOURCE_BUILD_LOG" >&2
  exit 9
fi

required_owner_facts=(
  "explicit_approval_replay_audit_owner_present=true"
  "explicit_approval_rerun_contract_input=true"
  "regression_suite_packet_audit_required=true"
  "handoff_replay_contract_required=true"
  "source_build_replay_guard_required=true"
  "focused_replay_audit_suite_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing owner fact $fact" >&2
    exit 10
  fi
done

required_audit_facts=(
  "suite_packet_audit_passed=true"
  "nested_packet_paths_reachable=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_audit_facts[@]}"; do
  if ! grep -F "$fact" "$AUDIT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing audit fact $fact" >&2
    exit 11
  fi
done

required_handoff_facts=(
  "handoff_replay_contract_passed=true"
  "nested_packet_stop_lines_consistent=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$HANDOFF_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing handoff fact $fact" >&2
    exit 12
  fi
done

required_source_facts=(
  "replay_audit_owner_probe_passed=true"
  "suite_packet_audit_passed=true"
  "runtime_package_build_passed=true"
  "source_build_replay_guard_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing source/build fact $fact" >&2
    exit 13
  fi
done

handoff_replay_packet="$(grep -Eo 'handoff_replay_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)"
source_build_replay_packet="$(grep -Eo 'source_build_replay_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$audit_packet" "$handoff_replay_packet" "$source_build_replay_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: missing packet $packet" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: protected path modified" >&2
  exit 15
fi

{
  echo "explicit_approval_replay_audit_suite_version=1"
  echo "replay_audit_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "suite_packet_audit_passed=true"
  echo "audit_log=$AUDIT_LOG"
  echo "audit_packet=$audit_packet"
  echo "handoff_replay_contract_passed=true"
  echo "handoff_log=$HANDOFF_LOG"
  echo "handoff_replay_packet=$handoff_replay_packet"
  echo "source_build_replay_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_replay_packet=$source_build_replay_packet"
  echo "explicit_approval_replay_audit_suite_passed=true"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "d3_runtime_native_probe_approval_required=true"
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
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: route_classification=runtime_native_probe_explicit_approval_replay_audit_suite"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: replay_audit_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: suite_packet_audit_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: handoff_replay_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: source_build_replay_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: explicit_approval_replay_audit_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: replay_audit_suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: audit_packet=$audit_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: handoff_replay_packet=$handoff_replay_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: source_build_replay_packet=$source_build_replay_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay audit suite: next_route=human_approved_d3_runtime_native_probe_execution_or_non_d3_replay_audit_rerun"
