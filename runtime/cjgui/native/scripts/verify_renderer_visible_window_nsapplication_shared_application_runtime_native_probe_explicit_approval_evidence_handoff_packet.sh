#!/usr/bin/env zsh
#
# 维护注释：本脚本把 explicit approval mesh rerun contract 与 source/build guard
# 聚合为 handoff packet，交给下一轮或人工 D3 审批前复核。
# Truth: handoff contract / rerun contract；不执行 runtime native probe，不消费 D3
# approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-evidence-handoff"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
RERUN_CONTRACT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_mesh_rerun_contract.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_source_build_guard.sh"
RERUN_LOG="$TMP_DIR/mesh-rerun-contract.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build-guard.log"
HANDOFF_PACKET="$TMP_DIR/explicit-approval-evidence-handoff.packet"
EXTERNAL_RERUN_PACKET="${CJGUI_EXPLICIT_APPROVAL_RERUN_PACKET:-}"
EXTERNAL_SOURCE_BUILD_PACKET="${CJGUI_EXPLICIT_APPROVAL_SOURCE_BUILD_PACKET:-}"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$RERUN_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$HANDOFF_PACKET"

for script in "$RERUN_CONTRACT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_RERUN_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_RERUN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: external rerun packet missing $EXTERNAL_RERUN_PACKET" >&2
    exit 5
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: external_rerun_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_mesh_rerun_contract"
    cat "$EXTERNAL_RERUN_PACKET"
  } > "$RERUN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-rerun" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$RERUN_CONTRACT" > "$RERUN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: mesh rerun contract failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: log=$RERUN_LOG" >&2
    exit 6
  fi
fi

if [[ -n "$EXTERNAL_SOURCE_BUILD_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_SOURCE_BUILD_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: external source/build packet missing $EXTERNAL_SOURCE_BUILD_PACKET" >&2
    exit 7
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: external_source_build_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_source_build_guard"
    cat "$EXTERNAL_SOURCE_BUILD_PACKET"
  } > "$SOURCE_BUILD_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-source-build" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: source build guard failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: log=$SOURCE_BUILD_LOG" >&2
    exit 8
  fi
fi

required_rerun_facts=(
  "route_classification=runtime_native_probe_explicit_approval_mesh_rerun_contract"
  "two_pass_mesh_rerun_contract_passed=true"
  "stable_non_d3_approval_facts_across_reruns=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_rerun_facts[@]}"; do
  if ! grep -F "$fact" "$RERUN_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: missing rerun fact $fact" >&2
    exit 9
  fi
done

required_source_build_facts=(
  "route_classification=runtime_native_probe_explicit_approval_source_build_guard"
  "rerun_contract_owner_probe_passed=true"
  "runtime_package_build_passed=true"
  "source_build_guard_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_source_build_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: missing source/build fact $fact" >&2
    exit 10
  fi
done

rerun_packet="${EXTERNAL_RERUN_PACKET:-$(grep -Eo 'rerun_packet_path=[^[:space:]]+' "$RERUN_LOG" | tail -1 | cut -d= -f2-)}"
source_build_packet="${EXTERNAL_SOURCE_BUILD_PACKET:-$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)}"
for packet in "$rerun_packet" "$source_build_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: missing packet $packet" >&2
    exit 11
  fi
done

first_smoke="$(grep -Eo '^first_smoke_environment_classification=[A-Za-z0-9_]+' "$rerun_packet" | tail -1 | cut -d= -f2)"
second_smoke="$(grep -Eo '^second_smoke_environment_classification=[A-Za-z0-9_]+' "$rerun_packet" | tail -1 | cut -d= -f2)"
environment_drift_between_mesh_reruns="$(grep -Eo '^environment_drift_between_mesh_reruns=(true|false)' "$rerun_packet" | tail -1 | cut -d= -f2)"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: protected path modified" >&2
  exit 12
fi

{
  echo "explicit_approval_evidence_handoff_packet_version=1"
  echo "mesh_rerun_contract_passed=true"
  echo "external_rerun_packet_used=$([[ -n "$EXTERNAL_RERUN_PACKET" ]] && echo true || echo false)"
  echo "rerun_log=$RERUN_LOG"
  echo "rerun_packet=$rerun_packet"
  echo "source_build_guard_passed=true"
  echo "external_source_build_packet_used=$([[ -n "$EXTERNAL_SOURCE_BUILD_PACKET" ]] && echo true || echo false)"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "handoff_packet_ready=true"
  echo "first_smoke_environment_classification=$first_smoke"
  echo "second_smoke_environment_classification=$second_smoke"
  echo "environment_drift_between_mesh_reruns=${environment_drift_between_mesh_reruns:-false}"
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
} > "$HANDOFF_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: route_classification=runtime_native_probe_explicit_approval_evidence_handoff_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: mesh_rerun_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: source_build_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: handoff_packet_ready=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: handoff_packet_path=$HANDOFF_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: rerun_packet=$rerun_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: source_build_packet=$source_build_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: first_smoke_environment_classification=$first_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: second_smoke_environment_classification=$second_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: environment_drift_between_mesh_reruns=${environment_drift_between_mesh_reruns:-false}"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval evidence handoff packet: renderer_state_write=false"
