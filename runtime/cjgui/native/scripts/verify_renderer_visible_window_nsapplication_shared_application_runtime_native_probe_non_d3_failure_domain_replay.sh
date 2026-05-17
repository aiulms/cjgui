#!/usr/bin/env zsh
#
# 维护注释：本脚本 fresh rerun capability detector 与 failure-domain matrix，
# 验证 non-D3 recovery 路线的 environment / failure-domain 分类仍然稳定。
# Truth: failure-domain replay guard；不执行 runtime native probe，不消费 D3
# approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-non-d3-failure-domain-replay"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
CAPABILITY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
FAILURE_MATRIX="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_failure_domain_matrix.sh"
CAPABILITY_LOG="$TMP_DIR/external-capability-detector.log"
FAILURE_MATRIX_LOG="$TMP_DIR/failure-domain-matrix.log"
REPLAY_PACKET="$TMP_DIR/non-d3-failure-domain-replay.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$CAPABILITY_LOG"
: > "$FAILURE_MATRIX_LOG"
: > "$REPLAY_PACKET"

for script in "$CAPABILITY_SCRIPT" "$FAILURE_MATRIX"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$CAPABILITY_SCRIPT" > "$CAPABILITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: capability detector failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: log=$CAPABILITY_LOG" >&2
  exit 5
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$FAILURE_MATRIX" > "$FAILURE_MATRIX_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: failure-domain matrix failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: log=$FAILURE_MATRIX_LOG" >&2
  exit 6
fi

required_capability_facts=(
  "route_classification=runtime_native_probe_external_capability_detector"
  "external_handoff_classification_passed=true"
  "capability_packet_created=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_capability_facts[@]}"; do
  if ! grep -F "$fact" "$CAPABILITY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: missing capability fact $fact" >&2
    exit 7
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
    echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: missing matrix fact $fact" >&2
    exit 8
  fi
done

capability_packet="$(grep -Eo 'capability_packet_path=[^[:space:]]+' "$CAPABILITY_LOG" | tail -1 | cut -d= -f2-)"
matrix_packet="$(grep -Eo 'matrix_packet_path=[^[:space:]]+' "$FAILURE_MATRIX_LOG" | tail -1 | cut -d= -f2-)"

for packet in "$capability_packet" "$matrix_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: missing packet $packet" >&2
    exit 9
  fi
done

capability_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
matrix_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
capability_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
matrix_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
capability_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$capability_packet" | tail -1 | cut -d= -f2)"
matrix_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
next_actor="$(grep -Eo '^next_actor=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"
required_shell="$(grep -Eo '^required_shell=[A-Za-z0-9_]+' "$matrix_packet" | tail -1 | cut -d= -f2)"

if [[ "$capability_smoke_classification" != "$matrix_smoke_classification" ||
  "$capability_failure_domain" != "$matrix_failure_domain" ||
  "$capability_smoke_exit_code" != "$matrix_smoke_exit_code" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: capability and matrix facts diverged" >&2
  exit 10
fi

if [[ "$next_actor" != "human_operator" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: unexpected next actor $next_actor" >&2
  exit 11
fi

case "$capability_smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$capability_smoke_exit_code" != "20" ||
      "$capability_failure_domain" != "automation_environment" ||
      "$required_shell" != "metal_capable_shell" ]]; then
      echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: inconsistent Metal-unavailable replay" >&2
      exit 12
    fi
    ;;
  automation_smoke_metal_capable)
    if [[ "$capability_smoke_exit_code" != "0" ||
      "$required_shell" != "explicitly_approved_shell" ]]; then
      echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: inconsistent Metal-capable replay" >&2
      exit 13
    fi
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: unexpected smoke classification $capability_smoke_classification" >&2
    exit 14
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: protected path modified" >&2
  exit 15
fi

{
  echo "non_d3_failure_domain_replay_version=1"
  echo "capability_detector_rerun_passed=true"
  echo "capability_log=$CAPABILITY_LOG"
  echo "capability_packet=$capability_packet"
  echo "failure_domain_matrix_rerun_passed=true"
  echo "failure_domain_matrix_log=$FAILURE_MATRIX_LOG"
  echo "failure_domain_matrix_packet=$matrix_packet"
  echo "failure_domain_replay_passed=true"
  echo "smoke_exit_code=$capability_smoke_exit_code"
  echo "smoke_environment_classification=$capability_smoke_classification"
  echo "failure_domain=$capability_failure_domain"
  echo "next_actor=$next_actor"
  echo "required_shell=$required_shell"
  echo "code_failure_domain=false"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$REPLAY_PACKET"

echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: route_classification=runtime_native_probe_non_d3_failure_domain_replay"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: capability_detector_rerun_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: failure_domain_matrix_rerun_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: failure_domain_replay_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: failure_domain_replay_packet_path=$REPLAY_PACKET"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: capability_packet=$capability_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: failure_domain_matrix_packet=$matrix_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: smoke_exit_code=$capability_smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: smoke_environment_classification=$capability_smoke_classification"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: failure_domain=$capability_failure_domain"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: next_actor=$next_actor"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: required_shell=$required_shell"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 failure-domain replay: renderer_state_write=false"
