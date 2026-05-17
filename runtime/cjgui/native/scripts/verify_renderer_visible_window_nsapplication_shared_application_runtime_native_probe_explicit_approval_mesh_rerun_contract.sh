#!/usr/bin/env zsh
#
# 维护注释：本脚本 two-pass 重跑 explicit approval evidence mesh runner，确认
# non-D3 approval facts 在重复运行中保持稳定，环境 classification 只允许在
# Metal-capable / Metal-unavailable automation shell 集合内变化。
# Truth: capability detector / rerun contract；不执行 runtime native probe，不消费
# D3 approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-mesh-rerun-contract"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
MESH_RUNNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_verification_mesh_runner.sh"
FIRST_LOG="$TMP_DIR/mesh-rerun-first.log"
SECOND_LOG="$TMP_DIR/mesh-rerun-second.log"
RERUN_PACKET="$TMP_DIR/explicit-approval-mesh-rerun-contract.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$FIRST_LOG"
: > "$SECOND_LOG"
: > "$RERUN_PACKET"

if [[ ! -x "$MESH_RUNNER" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: missing executable mesh runner $MESH_RUNNER" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/pass-1" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$MESH_RUNNER" > "$FIRST_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: first mesh run failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: log=$FIRST_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/pass-2" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$MESH_RUNNER" > "$SECOND_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: second mesh run failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: log=$SECOND_LOG" >&2
  exit 6
fi

required_mesh_facts=(
  "route_classification=runtime_native_probe_explicit_approval_verification_mesh_runner"
  "explicit_approval_verification_mesh_runner_passed=true"
  "handoff_packet_consistency_passed=true"
  "native_bridge_replay_guard_passed=true"
  "failure_domain_continuity_guard_passed=true"
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
)
for log in "$FIRST_LOG" "$SECOND_LOG"; do
  for fact in "${required_mesh_facts[@]}"; do
    if ! grep -F "$fact" "$log" >/dev/null 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: missing mesh fact $fact in $log" >&2
      exit 7
    fi
  done
done

first_packet="$(grep -Eo 'mesh_packet_path=[^[:space:]]+' "$FIRST_LOG" | tail -1 | cut -d= -f2-)"
second_packet="$(grep -Eo 'mesh_packet_path=[^[:space:]]+' "$SECOND_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$first_packet" "$second_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: missing mesh packet $packet" >&2
    exit 8
  fi
done

first_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$first_packet" | tail -1 | cut -d= -f2)"
second_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$second_packet" | tail -1 | cut -d= -f2)"
first_exit="$(grep -Eo '^smoke_exit_code=[0-9]+' "$first_packet" | tail -1 | cut -d= -f2)"
second_exit="$(grep -Eo '^smoke_exit_code=[0-9]+' "$second_packet" | tail -1 | cut -d= -f2)"
first_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$first_packet" | tail -1 | cut -d= -f2)"
second_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$second_packet" | tail -1 | cut -d= -f2)"

for classification in "$first_smoke" "$second_smoke"; do
  case "$classification" in
    automation_smoke_metal_capable|automation_smoke_metal_unavailable)
      ;;
    *)
      echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: unexpected smoke classification $classification" >&2
      exit 9
      ;;
  esac
done

if [[ "$first_smoke" == "automation_smoke_metal_capable" &&
  ( "$first_exit" != "0" || "$first_failure_domain" != "none" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: inconsistent first Metal-capable facts" >&2
  exit 10
fi
if [[ "$first_smoke" == "automation_smoke_metal_unavailable" &&
  ( "$first_exit" != "20" || "$first_failure_domain" != "automation_environment" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: inconsistent first Metal-unavailable facts" >&2
  exit 11
fi
if [[ "$second_smoke" == "automation_smoke_metal_capable" &&
  ( "$second_exit" != "0" || "$second_failure_domain" != "none" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: inconsistent second Metal-capable facts" >&2
  exit 12
fi
if [[ "$second_smoke" == "automation_smoke_metal_unavailable" &&
  ( "$second_exit" != "20" || "$second_failure_domain" != "automation_environment" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: inconsistent second Metal-unavailable facts" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: protected path modified" >&2
  exit 14
fi

if [[ "$first_smoke" == "$second_smoke" && "$first_failure_domain" == "$second_failure_domain" ]]; then
  environment_drift_between_mesh_reruns=false
else
  environment_drift_between_mesh_reruns=true
fi

{
  echo "explicit_approval_mesh_rerun_contract_version=1"
  echo "first_mesh_runner_passed=true"
  echo "first_log=$FIRST_LOG"
  echo "first_packet=$first_packet"
  echo "second_mesh_runner_passed=true"
  echo "second_log=$SECOND_LOG"
  echo "second_packet=$second_packet"
  echo "two_pass_mesh_rerun_contract_passed=true"
  echo "stable_non_d3_approval_facts_across_reruns=true"
  echo "first_smoke_exit_code=$first_exit"
  echo "second_smoke_exit_code=$second_exit"
  echo "first_smoke_environment_classification=$first_smoke"
  echo "second_smoke_environment_classification=$second_smoke"
  echo "first_failure_domain=$first_failure_domain"
  echo "second_failure_domain=$second_failure_domain"
  echo "environment_drift_between_mesh_reruns=$environment_drift_between_mesh_reruns"
  echo "allowed_environment_classification_set=metal_capable_or_metal_unavailable"
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
} > "$RERUN_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: route_classification=runtime_native_probe_explicit_approval_mesh_rerun_contract"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: first_mesh_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: second_mesh_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: two_pass_mesh_rerun_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: stable_non_d3_approval_facts_across_reruns=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: rerun_packet_path=$RERUN_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: first_packet=$first_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: second_packet=$second_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: first_smoke_environment_classification=$first_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: second_smoke_environment_classification=$second_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: environment_drift_between_mesh_reruns=$environment_drift_between_mesh_reruns"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval mesh rerun contract: renderer_state_write=false"
