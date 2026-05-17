#!/usr/bin/env zsh
#
# 维护注释：本脚本是 explicit approval rerun contract focused regression suite。
# 它串联 owner probe、mesh rerun contract、source/build guard 与 handoff packet。
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-regression-suite"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract_owner.sh"
MESH_RERUN="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_mesh_rerun_contract.sh"
SOURCE_BUILD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_source_build_guard.sh"
HANDOFF_PACKET="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_evidence_handoff_packet.sh"
OWNER_LOG="$TMP_DIR/rerun-contract-owner.log"
MESH_RERUN_LOG="$TMP_DIR/mesh-rerun-contract.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build-guard.log"
HANDOFF_LOG="$TMP_DIR/evidence-handoff-packet.log"
SUITE_PACKET="$TMP_DIR/explicit-approval-regression-suite.packet"
EXTERNAL_RERUN_PACKET="${CJGUI_EXPLICIT_APPROVAL_RERUN_PACKET:-}"
EXTERNAL_SOURCE_BUILD_PACKET="${CJGUI_EXPLICIT_APPROVAL_SOURCE_BUILD_PACKET:-}"
EXTERNAL_HANDOFF_PACKET="${CJGUI_EXPLICIT_APPROVAL_HANDOFF_PACKET:-}"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$MESH_RERUN_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$HANDOFF_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$MESH_RERUN" "$SOURCE_BUILD" "$HANDOFF_PACKET"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: log=$OWNER_LOG" >&2
  exit 5
fi
if [[ -n "$EXTERNAL_RERUN_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_RERUN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: external rerun packet missing $EXTERNAL_RERUN_PACKET" >&2
    exit 6
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: external_rerun_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_mesh_rerun_contract"
    cat "$EXTERNAL_RERUN_PACKET"
  } > "$MESH_RERUN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-mesh-rerun" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$MESH_RERUN" > "$MESH_RERUN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: mesh rerun contract failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: log=$MESH_RERUN_LOG" >&2
    exit 7
  fi
fi

if [[ -n "$EXTERNAL_SOURCE_BUILD_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_SOURCE_BUILD_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: external source/build packet missing $EXTERNAL_SOURCE_BUILD_PACKET" >&2
    exit 8
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: external_source_build_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_source_build_guard"
    cat "$EXTERNAL_SOURCE_BUILD_PACKET"
  } > "$SOURCE_BUILD_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-source-build" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$SOURCE_BUILD" > "$SOURCE_BUILD_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: source build guard failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: log=$SOURCE_BUILD_LOG" >&2
    exit 9
  fi
fi

if [[ -n "$EXTERNAL_HANDOFF_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_HANDOFF_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: external handoff packet missing $EXTERNAL_HANDOFF_PACKET" >&2
    exit 10
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: external_handoff_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_evidence_handoff_packet"
    cat "$EXTERNAL_HANDOFF_PACKET"
  } > "$HANDOFF_LOG"
else
  if ! env \
    TMPDIR="$TMP_DIR/nested-handoff" \
    CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" \
    CJGUI_EXPLICIT_APPROVAL_RERUN_PACKET="$EXTERNAL_RERUN_PACKET" \
    CJGUI_EXPLICIT_APPROVAL_SOURCE_BUILD_PACKET="$EXTERNAL_SOURCE_BUILD_PACKET" \
    zsh "$HANDOFF_PACKET" > "$HANDOFF_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: handoff packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: log=$HANDOFF_LOG" >&2
    exit 11
  fi
fi

required_owner_facts=(
  "explicit_approval_rerun_contract_owner_present=true"
  "explicit_approval_handoff_evidence_mesh_input=true"
  "two_pass_mesh_rerun_contract_required=true"
  "source_build_guard_required=true"
  "evidence_handoff_packet_required=true"
  "focused_regression_suite_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: missing owner fact $fact" >&2
    exit 12
  fi
done

required_mesh_facts=(
  "two_pass_mesh_rerun_contract_passed=true"
  "stable_non_d3_approval_facts_across_reruns=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_mesh_facts[@]}"; do
  if ! grep -F "$fact" "$MESH_RERUN_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: missing mesh rerun fact $fact" >&2
    exit 13
  fi
done

required_source_facts=(
  "runtime_package_build_passed=true"
  "source_build_guard_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: missing source/build fact $fact" >&2
    exit 14
  fi
done

required_handoff_facts=(
  "route_classification=runtime_native_probe_explicit_approval_evidence_handoff_packet"
  "mesh_rerun_contract_passed=true"
  "source_build_guard_passed=true"
  "handoff_packet_ready=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$HANDOFF_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: missing handoff fact $fact" >&2
    exit 15
  fi
done

rerun_packet="${EXTERNAL_RERUN_PACKET:-$(grep -Eo 'rerun_packet_path=[^[:space:]]+' "$MESH_RERUN_LOG" | tail -1 | cut -d= -f2-)}"
source_build_packet="${EXTERNAL_SOURCE_BUILD_PACKET:-$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)}"
handoff_packet="${EXTERNAL_HANDOFF_PACKET:-$(grep -Eo 'handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)}"
for packet in "$rerun_packet" "$source_build_packet" "$handoff_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: missing packet $packet" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: protected path modified" >&2
  exit 17
fi

{
  echo "explicit_approval_regression_suite_version=1"
  echo "rerun_contract_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "mesh_rerun_contract_passed=true"
  echo "external_rerun_packet_used=$([[ -n "$EXTERNAL_RERUN_PACKET" ]] && echo true || echo false)"
  echo "mesh_rerun_log=$MESH_RERUN_LOG"
  echo "rerun_packet=$rerun_packet"
  echo "source_build_guard_passed=true"
  echo "external_source_build_packet_used=$([[ -n "$EXTERNAL_SOURCE_BUILD_PACKET" ]] && echo true || echo false)"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "evidence_handoff_packet_passed=true"
  echo "external_handoff_packet_used=$([[ -n "$EXTERNAL_HANDOFF_PACKET" ]] && echo true || echo false)"
  echo "handoff_log=$HANDOFF_LOG"
  echo "handoff_packet=$handoff_packet"
  echo "explicit_approval_regression_suite_passed=true"
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

echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: route_classification=runtime_native_probe_explicit_approval_regression_suite"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: rerun_contract_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: mesh_rerun_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: source_build_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: evidence_handoff_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: explicit_approval_regression_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval regression suite: next_route=human_approved_d3_runtime_native_probe_execution_or_non_d3_regression_suite_rerun"
