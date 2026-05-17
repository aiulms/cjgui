#!/usr/bin/env zsh
#
# 维护注释：本脚本把 runtime native-readiness external capability packet
# 转换为 failure-domain matrix。它用于后续 rerun / handoff 判断，不执行 runtime
# native probe，也不消费 D3 approval。
# Truth: environment / failure-domain classification follow-up；记录 toolchain、
# smoke、approval、code-path 与下一执行者矩阵。
# Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
# activation，不修改 activation policy，不运行 event loop / bounded pump，不创建
# visible window，不 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-failure-domain-matrix"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
CAPABILITY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
CAPABILITY_LOG="$TMP_DIR/external-capability-detector.log"
MATRIX_PACKET="$TMP_DIR/runtime-native-probe-failure-domain.matrix"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$CAPABILITY_LOG"
: > "$MATRIX_PACKET"

if [[ ! -x "$CAPABILITY_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: missing executable capability script $CAPABILITY_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$CAPABILITY_SCRIPT" > "$CAPABILITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: external capability detector failed" >&2
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: log=$CAPABILITY_LOG" >&2
  exit 5
fi

required_capability_output_facts=(
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

for fact in "${required_capability_output_facts[@]}"; do
  if ! grep -F "$fact" "$CAPABILITY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe failure domain matrix: missing capability output fact $fact" >&2
    exit 6
  fi
done

capability_packet="$(grep -Eo 'capability_packet_path=[^[:space:]]+' "$CAPABILITY_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$capability_packet" || ! -f "$capability_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: missing capability packet" >&2
  exit 7
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$capability_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
cjpm_available="$(grep -Eo '^cjpm_available=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
cjc_available="$(grep -Eo '^cjc_available=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
clang_available="$(grep -Eo '^clang_available=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
auto_close_smoke_available="$(grep -Eo '^auto_close_smoke_available=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
external_handoff_required="$(grep -Eo '^external_handoff_required=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
external_metal_capable_shell_required="$(grep -Eo '^external_metal_capable_shell_required=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
metal_capable_shell_observed="$(grep -Eo '^metal_capable_shell_observed=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
d3_approval_env_true="$(grep -Eo '^d3_approval_env_true=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"

if [[ "$cjpm_available" != "true" || "$cjc_available" != "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: toolchain unavailable" >&2
  exit 8
fi
if [[ "$clang_available" != "true" || "$auto_close_smoke_available" != "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: native probe prerequisites unavailable" >&2
  exit 9
fi
if [[ "$d3_approval_env_true" != "false" ]]; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: D3 approval unexpectedly present" >&2
  exit 10
fi

case "$smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" || "$failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe failure domain matrix: inconsistent Metal-unavailable matrix" >&2
      exit 11
    fi
    matrix_environment_plane="automation_environment_blocked"
    matrix_next_actor="human_operator"
    matrix_required_shell="metal_capable_shell"
    ;;
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" || "$metal_capable_shell_observed" != "true" ]]; then
      echo "cjgui renderer NSApplication runtime native probe failure domain matrix: inconsistent Metal-capable matrix" >&2
      exit 12
    fi
    matrix_environment_plane="metal_capable_shell_observed"
    matrix_next_actor="human_operator"
    matrix_required_shell="explicitly_approved_shell"
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe failure domain matrix: unexpected smoke classification $smoke_classification" >&2
    exit 13
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe failure domain matrix: protected path modified" >&2
  exit 14
fi

{
  echo "failure_domain_matrix_version=1"
  echo "capability_detector_passed=true"
  echo "capability_log=$CAPABILITY_LOG"
  echo "capability_packet=$capability_packet"
  echo "toolchain_plane=cjpm_cjc_available"
  echo "native_probe_prerequisite_plane=clang_and_auto_close_smoke_available"
  echo "environment_plane=$matrix_environment_plane"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "code_plane=code_failure_domain_false"
  echo "approval_plane=d3_approval_absent"
  echo "handoff_plane=external_handoff_required_$external_handoff_required"
  echo "required_shell_plane=external_metal_capable_shell_required_$external_metal_capable_shell_required"
  echo "next_actor=$matrix_next_actor"
  echo "required_shell=$matrix_required_shell"
  echo "source_build_probe_route_available=true"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$MATRIX_PACKET"

required_matrix_facts=(
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

for fact in "${required_matrix_facts[@]}"; do
  if ! grep -F "$fact" "$MATRIX_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe failure domain matrix: missing matrix fact $fact" >&2
    exit 15
  fi
done

echo "cjgui renderer NSApplication runtime native probe failure domain matrix: route_classification=runtime_native_probe_failure_domain_matrix"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: capability_detector_passed=true"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: matrix_packet_created=true"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: matrix_packet_path=$MATRIX_PACKET"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: toolchain_plane=cjpm_cjc_available"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: native_probe_prerequisite_plane=clang_and_auto_close_smoke_available"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: environment_plane=$matrix_environment_plane"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: approval_plane=d3_approval_absent"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: next_actor=$matrix_next_actor"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: required_shell=$matrix_required_shell"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: source_build_probe_route_available=true"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe failure domain matrix: renderer_state_write=false"
