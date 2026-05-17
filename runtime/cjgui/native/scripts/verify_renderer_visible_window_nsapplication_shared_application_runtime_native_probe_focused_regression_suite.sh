#!/usr/bin/env zsh
#
# 维护注释：本脚本是 runtime native-readiness non-D3 recovery 的 focused
# regression suite。它编排 source/build/probe guard、failure-domain matrix 与
# stage86 recovery aggregation，提供一条可重复的 non-hard-boundary rerun entry。
# Truth: focused regression orchestration runner；不执行 runtime native probe，不
# 调用 application singleton accessor，不创建 singleton，不扩 native bridge，不消费
# human approval，不升级 production ownership truth。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-focused-regression-suite"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence_guard.sh"
FAILURE_MATRIX="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_failure_domain_matrix.sh"
AGGREGATION_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_recovery_guard_aggregation.sh"
SOURCE_BUILD_LOG="$TMP_DIR/source-build-probe-evidence-guard.log"
FAILURE_MATRIX_LOG="$TMP_DIR/failure-domain-matrix.log"
AGGREGATION_LOG="$TMP_DIR/recovery-aggregation.log"
SUITE_PACKET="$TMP_DIR/focused-regression-suite.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$SOURCE_BUILD_LOG"
: > "$FAILURE_MATRIX_LOG"
: > "$AGGREGATION_LOG"
: > "$SUITE_PACKET"

for script in "$SOURCE_BUILD_GUARD" "$FAILURE_MATRIX" "$AGGREGATION_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe focused regression suite: missing executable script $script" >&2
    exit 3
  fi
done

if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: source/build/probe guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: log=$SOURCE_BUILD_LOG" >&2
  exit 5
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$FAILURE_MATRIX" > "$FAILURE_MATRIX_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: failure-domain matrix failed" >&2
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: log=$FAILURE_MATRIX_LOG" >&2
  exit 6
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$AGGREGATION_GUARD" > "$AGGREGATION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: recovery aggregation guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: log=$AGGREGATION_LOG" >&2
  exit 7
fi

required_source_build_facts=(
  "route_classification=runtime_native_probe_source_build_probe_evidence_guard"
  "owner_probe_passed=true"
  "recovery_aggregation_guard_passed=true"
  "runtime_package_build_passed=true"
  "source_build_probe_evidence_strengthened=true"
  "code_failure_domain=false"
  "automation_can_continue_non_d3_recovery=true"
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
    echo "cjgui renderer NSApplication runtime native probe focused regression suite: missing source/build fact $fact" >&2
    exit 8
  fi
done

required_matrix_facts=(
  "route_classification=runtime_native_probe_failure_domain_matrix"
  "capability_detector_passed=true"
  "matrix_packet_created=true"
  "toolchain_plane=cjpm_cjc_available"
  "native_probe_prerequisite_plane=clang_and_auto_close_smoke_available"
  "approval_plane=d3_approval_absent"
  "source_build_probe_route_available=true"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_matrix_facts[@]}"; do
  if ! grep -F "$fact" "$FAILURE_MATRIX_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe focused regression suite: missing matrix fact $fact" >&2
    exit 9
  fi
done

required_aggregation_facts=(
  "route_classification=runtime_native_probe_recovery_guard_aggregation"
  "related_regression_guards_aggregated=true"
  "non_metal_recovery_route_landed=true"
  "automation_can_continue_non_d3_recovery=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_aggregation_facts[@]}"; do
  if ! grep -F "$fact" "$AGGREGATION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe focused regression suite: missing aggregation fact $fact" >&2
    exit 10
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe focused regression suite: protected path modified" >&2
  exit 11
fi

source_build_packet="$(grep -Eo 'evidence_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
matrix_packet="$(grep -Eo 'matrix_packet_path=[^[:space:]]+' "$FAILURE_MATRIX_LOG" | tail -1 | cut -d= -f2-)"
aggregation_packet="$(grep -Eo 'aggregation_packet_path=[^[:space:]]+' "$AGGREGATION_LOG" | tail -1 | cut -d= -f2-)"

for packet in "$source_build_packet" "$matrix_packet" "$aggregation_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe focused regression suite: missing nested packet $packet" >&2
    exit 12
  fi
done

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"

{
  echo "focused_regression_suite_packet_version=1"
  echo "source_build_probe_guard_passed=true"
  echo "source_build_probe_guard_log=$SOURCE_BUILD_LOG"
  echo "source_build_probe_packet=$source_build_packet"
  echo "failure_domain_matrix_passed=true"
  echo "failure_domain_matrix_log=$FAILURE_MATRIX_LOG"
  echo "failure_domain_matrix_packet=$matrix_packet"
  echo "recovery_aggregation_guard_passed=true"
  echo "recovery_aggregation_log=$AGGREGATION_LOG"
  echo "recovery_aggregation_packet=$aggregation_packet"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "focused_regression_suite_passed=true"
  echo "source_build_probe_evidence_strengthened=true"
  echo "failure_domain_matrix_aggregated=true"
  echo "related_regression_guards_aggregated=true"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "code_failure_domain=false"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$SUITE_PACKET"

required_suite_facts=(
  "focused_regression_suite_packet_version=1"
  "source_build_probe_guard_passed=true"
  "failure_domain_matrix_passed=true"
  "recovery_aggregation_guard_passed=true"
  "focused_regression_suite_passed=true"
  "source_build_probe_evidence_strengthened=true"
  "failure_domain_matrix_aggregated=true"
  "related_regression_guards_aggregated=true"
  "automation_can_continue_non_d3_recovery=true"
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
  if ! grep -F "$fact" "$SUITE_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe focused regression suite: missing suite fact $fact" >&2
    exit 13
  fi
done

echo "cjgui renderer NSApplication runtime native probe focused regression suite: route_classification=runtime_native_probe_focused_regression_suite"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: source_build_probe_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: failure_domain_matrix_passed=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: recovery_aggregation_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: focused_regression_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: source_build_probe_evidence_strengthened=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: failure_domain_matrix_aggregated=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: related_regression_guards_aggregated=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe focused regression suite: next_route=human_approved_d3_runtime_native_probe_execution_or_non_d3_regression_suite_rerun"
