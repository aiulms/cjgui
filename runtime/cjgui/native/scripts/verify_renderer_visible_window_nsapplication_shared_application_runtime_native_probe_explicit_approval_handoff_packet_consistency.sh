#!/usr/bin/env zsh
#
# 维护注释：本脚本重跑 explicit approval handoff runner，并检查 handoff、
# approval、native evidence 与 drift packet 的关键事实一致性。
# Truth: capability detector / handoff contract 后续路线；不执行 runtime native
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-packet-consistency"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
HANDOFF_RUNNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_runner.sh"
RUNNER_LOG="$TMP_DIR/explicit-approval-handoff-runner.log"
CONSISTENCY_PACKET="$TMP_DIR/explicit-approval-handoff-packet-consistency.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$RUNNER_LOG"
: > "$CONSISTENCY_PACKET"

if [[ ! -x "$HANDOFF_RUNNER" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: missing executable handoff runner $HANDOFF_RUNNER" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-runner" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$HANDOFF_RUNNER" > "$RUNNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: handoff runner failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: log=$RUNNER_LOG" >&2
  exit 5
fi

required_runner_facts=(
  "route_classification=runtime_native_probe_explicit_approval_handoff_runner"
  "explicit_approval_owner_probe_passed=true"
  "approval_gate_packet_passed=true"
  "route_scoped_native_bridge_evidence_passed=true"
  "environment_drift_replay_passed=true"
  "explicit_approval_handoff_runner_passed=true"
  "d3_runtime_native_probe_approval_required=true"
  "approved_runtime_native_probe_execution_admitted=false"
  "metal_capable_shell_does_not_imply_approval=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_runner_facts[@]}"; do
  if ! grep -F "$fact" "$RUNNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: missing runner fact $fact" >&2
    exit 6
  fi
done

handoff_packet="$(grep -Eo 'handoff_packet_path=[^[:space:]]+' "$RUNNER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: missing handoff packet" >&2
  exit 7
fi

approval_packet="$(grep -Eo '^approval_packet=[^[:space:]]+' "$handoff_packet" | tail -1 | cut -d= -f2-)"
native_packet="$(grep -Eo '^native_packet=[^[:space:]]+' "$handoff_packet" | tail -1 | cut -d= -f2-)"
drift_packet="$(grep -Eo '^drift_packet=[^[:space:]]+' "$handoff_packet" | tail -1 | cut -d= -f2-)"
for packet in "$approval_packet" "$native_packet" "$drift_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: missing packet $packet" >&2
    exit 8
  fi
done

required_handoff_packet_facts=(
  "explicit_approval_handoff_runner_version=1"
  "explicit_approval_owner_probe_passed=true"
  "approval_gate_packet_passed=true"
  "route_scoped_native_bridge_evidence_passed=true"
  "environment_drift_replay_passed=true"
  "explicit_approval_handoff_runner_passed=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "d3_runtime_native_probe_approval_required=true"
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
)
for fact in "${required_handoff_packet_facts[@]}"; do
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: missing handoff packet fact $fact" >&2
    exit 9
  fi
done

handoff_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$handoff_packet" | tail -1 | cut -d= -f2)"
approval_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
native_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$native_packet" | tail -1 | cut -d= -f2)"
handoff_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$handoff_packet" | tail -1 | cut -d= -f2)"
approval_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$approval_packet" | tail -1 | cut -d= -f2)"
native_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$native_packet" | tail -1 | cut -d= -f2)"
handoff_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$handoff_packet" | tail -1 | cut -d= -f2)"
approval_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
native_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$native_packet" | tail -1 | cut -d= -f2)"

if [[ "$handoff_smoke" != "$approval_smoke" || "$handoff_smoke" != "$native_smoke" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: smoke classification mismatch" >&2
  exit 10
fi
if [[ "$handoff_exit_code" != "$approval_exit_code" || "$handoff_exit_code" != "$native_exit_code" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: smoke exit code mismatch" >&2
  exit 11
fi
if [[ "$handoff_failure_domain" != "$approval_failure_domain" || "$handoff_failure_domain" != "$native_failure_domain" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: failure-domain mismatch" >&2
  exit 12
fi

case "$handoff_smoke" in
  automation_smoke_metal_capable)
    if [[ "$handoff_exit_code" != "0" || "$handoff_failure_domain" != "none" ]]; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: inconsistent Metal-capable facts" >&2
      exit 13
    fi
    ;;
  automation_smoke_metal_unavailable)
    if [[ "$handoff_exit_code" != "20" || "$handoff_failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: inconsistent Metal-unavailable facts" >&2
      exit 14
    fi
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: unexpected smoke classification $handoff_smoke" >&2
    exit 15
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: protected path modified" >&2
  exit 16
fi

{
  echo "explicit_approval_handoff_packet_consistency_version=1"
  echo "handoff_runner_passed=true"
  echo "runner_log=$RUNNER_LOG"
  echo "handoff_packet=$handoff_packet"
  echo "approval_packet=$approval_packet"
  echo "native_packet=$native_packet"
  echo "drift_packet=$drift_packet"
  echo "handoff_packet_consistency_passed=true"
  echo "cross_packet_smoke_consistency_passed=true"
  echo "cross_packet_failure_domain_consistency_passed=true"
  echo "smoke_exit_code=$handoff_exit_code"
  echo "smoke_environment_classification=$handoff_smoke"
  echo "failure_domain=$handoff_failure_domain"
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
} > "$CONSISTENCY_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: route_classification=runtime_native_probe_explicit_approval_handoff_packet_consistency"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: handoff_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: handoff_packet_consistency_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: cross_packet_smoke_consistency_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: cross_packet_failure_domain_consistency_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: packet_consistency_path=$CONSISTENCY_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: approval_packet=$approval_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: native_packet=$native_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: drift_packet=$drift_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: smoke_exit_code=$handoff_exit_code"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: smoke_environment_classification=$handoff_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: failure_domain=$handoff_failure_domain"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: d3_runtime_native_probe_approval_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: approved_runtime_native_probe_execution_admitted=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: metal_capable_shell_does_not_imply_approval=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff packet consistency: renderer_state_write=false"
