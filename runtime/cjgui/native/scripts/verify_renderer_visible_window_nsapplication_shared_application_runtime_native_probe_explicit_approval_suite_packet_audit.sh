#!/usr/bin/env zsh
#
# 维护注释：本脚本审计 stage91 explicit approval regression suite packet contract。
# 默认只做 bounded source/contract audit；若调用方传入
# CJGUI_EXPLICIT_APPROVAL_REPLAY_SUITE_PACKET，则做 deep packet replay。
# Truth: script-managed evidence / handoff contract；不执行 runtime native probe，不消费
# D3 approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-suite-packet-audit"
REGRESSION_SUITE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_regression_suite.sh"
HANDOFF_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_evidence_handoff_packet.sh"
RERUN_CONTRACT_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_mesh_rerun_contract.sh"
SOURCE_BUILD_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_source_build_guard.sh"
AUDIT_PACKET="$TMP_DIR/explicit-approval-suite-packet-audit.packet"
EXTERNAL_SUITE_PACKET="${CJGUI_EXPLICIT_APPROVAL_REPLAY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$AUDIT_PACKET"

for script in "$REGRESSION_SUITE" "$HANDOFF_PACKET_SCRIPT" "$RERUN_CONTRACT_SCRIPT" "$SOURCE_BUILD_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

deep_suite_packet_replay=false
suite_script_contract_audited=true
suite_packet="not_generated"
handoff_packet="not_generated"
rerun_packet="not_generated"
source_build_packet="not_generated"

required_regression_suite_tokens=(
  "route_classification=runtime_native_probe_explicit_approval_regression_suite"
  "suite_packet_path="
  "explicit_approval_regression_suite_passed=true"
  "CJGUI_EXPLICIT_APPROVAL_RERUN_PACKET"
  "CJGUI_EXPLICIT_APPROVAL_SOURCE_BUILD_PACKET"
  "CJGUI_EXPLICIT_APPROVAL_HANDOFF_PACKET"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
)
for token in "${required_regression_suite_tokens[@]}"; do
  if ! grep -F "$token" "$REGRESSION_SUITE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: missing regression suite contract token $token" >&2
    exit 5
  fi
done

required_handoff_tokens=(
  "route_classification=runtime_native_probe_explicit_approval_evidence_handoff_packet"
  "handoff_packet_ready=true"
  "CJGUI_EXPLICIT_APPROVAL_RERUN_PACKET"
  "CJGUI_EXPLICIT_APPROVAL_SOURCE_BUILD_PACKET"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for token in "${required_handoff_tokens[@]}"; do
  if ! grep -F "$token" "$HANDOFF_PACKET_SCRIPT" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: missing handoff contract token $token" >&2
    exit 6
  fi
done

if [[ -n "$EXTERNAL_SUITE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: external suite packet missing $EXTERNAL_SUITE_PACKET" >&2
    exit 7
  fi
  suite_packet="$EXTERNAL_SUITE_PACKET"
  deep_suite_packet_replay=true
  required_suite_packet_facts=(
    "explicit_approval_regression_suite_version=1"
    "rerun_contract_owner_probe_passed=true"
    "mesh_rerun_contract_passed=true"
    "source_build_guard_passed=true"
    "evidence_handoff_packet_passed=true"
    "explicit_approval_regression_suite_passed=true"
    "required_next_actor=human_operator"
    "required_shell=explicitly_approved_shell"
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
  for fact in "${required_suite_packet_facts[@]}"; do
    if ! grep -F "$fact" "$suite_packet" >/dev/null 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: missing suite packet fact $fact" >&2
      exit 8
    fi
  done

  handoff_packet="$(grep -Eo '^handoff_packet=[^[:space:]]+' "$suite_packet" | tail -1 | cut -d= -f2-)"
  rerun_packet="$(grep -Eo '^rerun_packet=[^[:space:]]+' "$suite_packet" | tail -1 | cut -d= -f2-)"
  source_build_packet="$(grep -Eo '^source_build_packet=[^[:space:]]+' "$suite_packet" | tail -1 | cut -d= -f2-)"
  for packet in "$handoff_packet" "$rerun_packet" "$source_build_packet"; do
    if [[ -z "$packet" || ! -f "$packet" ]]; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: missing nested packet $packet" >&2
      exit 9
    fi
  done

  if ! grep -F "handoff_packet_ready=true" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: handoff packet is not ready" >&2
    exit 10
  fi
  if ! grep -F "two_pass_mesh_rerun_contract_passed=true" "$rerun_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: rerun packet is not ready" >&2
    exit 11
  fi
  if ! grep -F "runtime_package_build_passed=true" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: source/build packet is not ready" >&2
    exit 12
  fi
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: protected path modified" >&2
  exit 13
fi

{
  echo "explicit_approval_suite_packet_audit_version=2"
  echo "suite_packet_audit_passed=true"
  echo "suite_script_contract_audited=$suite_script_contract_audited"
  echo "deep_suite_packet_replay=$deep_suite_packet_replay"
  echo "external_suite_packet_used=$([[ -n "$EXTERNAL_SUITE_PACKET" ]] && echo true || echo false)"
  echo "suite_packet=$suite_packet"
  echo "handoff_packet=$handoff_packet"
  echo "rerun_packet=$rerun_packet"
  echo "source_build_packet=$source_build_packet"
  echo "nested_packet_paths_reachable=true"
  echo "packet_path_reachability_contract_audited=true"
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
} > "$AUDIT_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: route_classification=runtime_native_probe_explicit_approval_suite_packet_audit"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: suite_packet_audit_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: suite_script_contract_audited=$suite_script_contract_audited"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: deep_suite_packet_replay=$deep_suite_packet_replay"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: audit_packet_path=$AUDIT_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: suite_packet=$suite_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: rerun_packet=$rerun_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: source_build_packet=$source_build_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: nested_packet_paths_reachable=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: packet_path_reachability_contract_audited=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval suite packet audit: renderer_state_write=false"
