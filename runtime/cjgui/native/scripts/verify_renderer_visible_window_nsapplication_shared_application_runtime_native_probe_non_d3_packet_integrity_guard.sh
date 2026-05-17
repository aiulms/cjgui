#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness non-D3 rerun 路线的
# script-managed packet integrity。它 fresh rerun focused regression suite，
# 再用 anchored packet facts 校验 source/build/probe、failure-domain matrix 与
# recovery aggregation packet 一致。
# Truth: packet integrity guard；不执行 runtime native probe，不消费 D3 approval，
# 不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-non-d3-packet-integrity"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
FOCUSED_SUITE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_focused_regression_suite.sh"
FOCUSED_SUITE_LOG="$TMP_DIR/focused-regression-suite.log"
INTEGRITY_PACKET="$TMP_DIR/non-d3-packet-integrity.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$FOCUSED_SUITE_LOG"
: > "$INTEGRITY_PACKET"

if [[ ! -x "$FOCUSED_SUITE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing executable focused suite $FOCUSED_SUITE" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$FOCUSED_SUITE" > "$FOCUSED_SUITE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: focused regression suite failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: log=$FOCUSED_SUITE_LOG" >&2
  exit 5
fi

required_suite_output_facts=(
  "route_classification=runtime_native_probe_focused_regression_suite"
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

for fact in "${required_suite_output_facts[@]}"; do
  if ! grep -F "$fact" "$FOCUSED_SUITE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing focused suite output fact $fact" >&2
    exit 6
  fi
done

suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$FOCUSED_SUITE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$suite_packet" || ! -f "$suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing suite packet" >&2
  exit 7
fi

source_build_packet="$(grep -Eo '^source_build_probe_packet=[^[:space:]]+' "$suite_packet" | tail -1 | cut -d= -f2-)"
matrix_packet="$(grep -Eo '^failure_domain_matrix_packet=[^[:space:]]+' "$suite_packet" | tail -1 | cut -d= -f2-)"
aggregation_packet="$(grep -Eo '^recovery_aggregation_packet=[^[:space:]]+' "$suite_packet" | tail -1 | cut -d= -f2-)"

for packet in "$source_build_packet" "$matrix_packet" "$aggregation_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing nested packet $packet" >&2
    exit 8
  fi
done

required_source_packet_facts=(
  "source_build_probe_evidence_packet_version=1"
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
  "runtime_state_write=false"
  "cjpm_toml_change=false"
)

required_matrix_packet_facts=(
  "failure_domain_matrix_version=1"
  "capability_detector_passed=true"
  "toolchain_plane=cjpm_cjc_available"
  "native_probe_prerequisite_plane=clang_and_auto_close_smoke_available"
  "code_plane=code_failure_domain_false"
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

required_aggregation_packet_facts=(
  "aggregation_packet_version=1"
  "handoff_rerun_contract_passed=true"
  "failure_domain_guard_nested=true"
  "external_handoff_classification_nested=true"
  "capability_detector_nested=true"
  "related_regression_guards_aggregated=true"
  "code_failure_domain=false"
  "non_metal_recovery_route_landed=true"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_source_packet_facts[@]}"; do
  if ! grep -F "$fact" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing source packet fact $fact" >&2
    exit 9
  fi
done

for fact in "${required_matrix_packet_facts[@]}"; do
  if ! grep -F "$fact" "$matrix_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing matrix packet fact $fact" >&2
    exit 10
  fi
done

for fact in "${required_aggregation_packet_facts[@]}"; do
  if ! grep -F "$fact" "$aggregation_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: missing aggregation packet fact $fact" >&2
    exit 11
  fi
done

source_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$source_build_packet" | tail -1 | cut -d= -f2)"
matrix_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
aggregation_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$aggregation_packet" | tail -1 | cut -d= -f2)"
source_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$source_build_packet" | tail -1 | cut -d= -f2)"
matrix_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
aggregation_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$aggregation_packet" | tail -1 | cut -d= -f2)"
source_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$source_build_packet" | tail -1 | cut -d= -f2)"
matrix_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
aggregation_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$aggregation_packet" | tail -1 | cut -d= -f2)"

if [[ "$source_smoke_classification" != "$matrix_smoke_classification" ||
  "$source_smoke_classification" != "$aggregation_smoke_classification" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: inconsistent smoke classifications" >&2
  exit 12
fi
if [[ "$source_failure_domain" != "$matrix_failure_domain" ||
  "$source_failure_domain" != "$aggregation_failure_domain" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: inconsistent failure domains" >&2
  exit 13
fi
if [[ "$source_smoke_exit_code" != "$matrix_smoke_exit_code" ||
  "$source_smoke_exit_code" != "$aggregation_smoke_exit_code" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: inconsistent smoke exit codes" >&2
  exit 14
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: protected path modified" >&2
  exit 15
fi

{
  echo "non_d3_packet_integrity_version=1"
  echo "focused_regression_suite_rerun_passed=true"
  echo "focused_regression_suite_log=$FOCUSED_SUITE_LOG"
  echo "focused_regression_suite_packet=$suite_packet"
  echo "source_build_probe_packet=$source_build_packet"
  echo "failure_domain_matrix_packet=$matrix_packet"
  echo "recovery_aggregation_packet=$aggregation_packet"
  echo "anchored_packet_integrity_guard_passed=true"
  echo "packet_smoke_exit_code=$source_smoke_exit_code"
  echo "smoke_exit_code=$source_smoke_exit_code"
  echo "smoke_environment_classification=$source_smoke_classification"
  echo "failure_domain=$source_failure_domain"
  echo "code_failure_domain=false"
  echo "runtime_package_build_passed=true"
  echo "source_build_probe_evidence_strengthened=true"
  echo "failure_domain_matrix_aggregated=true"
  echo "related_regression_guards_aggregated=true"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$INTEGRITY_PACKET"

echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: route_classification=runtime_native_probe_non_d3_packet_integrity_guard"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: focused_regression_suite_rerun_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: anchored_packet_integrity_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: packet_integrity_packet_path=$INTEGRITY_PACKET"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: focused_regression_suite_packet=$suite_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: source_build_probe_packet=$source_build_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: failure_domain_matrix_packet=$matrix_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: recovery_aggregation_packet=$aggregation_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: smoke_exit_code=$source_smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: smoke_environment_classification=$source_smoke_classification"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: failure_domain=$source_failure_domain"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: source_build_probe_evidence_strengthened=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: failure_domain_matrix_aggregated=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: related_regression_guards_aggregated=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 packet integrity guard: renderer_state_write=false"
