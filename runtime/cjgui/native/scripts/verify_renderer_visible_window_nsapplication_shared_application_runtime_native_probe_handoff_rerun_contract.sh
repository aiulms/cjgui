#!/usr/bin/env zsh
#
# 维护注释：本脚本为 runtime native-readiness probe 的 external handoff
# 增加 rerun contract。它消费 capability detector packet，并生成一份
# script-managed contract，说明下一次 D3 runtime native probe execution 只能在
# explicit human-approved Metal-capable shell 中恢复；当前 automation 不消费
# approval，也不执行 runtime native probe。
# Truth: 这是 probe/script 层 rerun contract；不新增 runtime readiness owner，
# 不执行 runtime native probe，不调用 production application singleton accessor，
# 不创建 singleton，不扩 native bridge，不消费 human approval，不升级 production
# ownership truth。
# Stop-line: 不调用 production sharedApplication accessor，不创建或激活
# NSApplication，不修改 activation policy，不运行 AppKit event loop / bounded
# pump，不执行 cleanup / teardown，不创建 visible window，不 visible order，不取
# nextDrawable，不 render / commit / present / GPU submission，不改 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-handoff-rerun-contract"
CAPABILITY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
CAPABILITY_LOG="$TMP_DIR/external-capability-detector.log"
RERUN_CONTRACT="$TMP_DIR/runtime-native-probe-handoff-rerun.contract"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$CAPABILITY_LOG"
: > "$RERUN_CONTRACT"

if [[ ! -x "$CAPABILITY_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: missing executable capability script $CAPABILITY_SCRIPT" >&2
  exit 3
fi

if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$CAPABILITY_SCRIPT" > "$CAPABILITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: external capability detector failed" >&2
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: log=$CAPABILITY_LOG" >&2
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
    echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: missing capability output fact $fact" >&2
    exit 6
  fi
done

capability_packet="$(grep -Eo 'capability_packet_path=[^[:space:]]+' "$CAPABILITY_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$capability_packet" || ! -f "$capability_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: missing capability packet" >&2
  exit 7
fi

required_capability_packet_facts=(
  "capability_packet_version=1"
  "external_handoff_classification_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_capability_packet_facts[@]}"; do
  if ! grep -F "$fact" "$capability_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: missing capability packet fact $fact" >&2
    exit 8
  fi
done

handoff_packet="$(grep -Eo '^handoff_packet=[^[:space:]]+' "$capability_packet" | tail -1 | cut -d= -f2-)"
smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$capability_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
external_handoff_required="$(grep -Eo '^external_handoff_required=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
external_metal_capable_shell_required="$(grep -Eo '^external_metal_capable_shell_required=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
metal_capable_shell_observed="$(grep -Eo '^metal_capable_shell_observed=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
d3_approval_env_true="$(grep -Eo '^d3_approval_env_true=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"

if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: missing source handoff packet" >&2
  exit 9
fi

if [[ "$d3_approval_env_true" != "false" ]]; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: D3 approval unexpectedly present" >&2
  exit 10
fi

contract_route="human_approved_d3_runtime_native_probe_execution_in_metal_capable_shell"
contract_waiting_on="explicit_human_approval_and_metal_capable_shell"
automation_can_continue_non_d3_recovery="true"

case "$smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" || "$failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: inconsistent Metal-unavailable capability facts" >&2
      exit 11
    fi
    ;;
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" || "$metal_capable_shell_observed" != "true" ]]; then
      echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: inconsistent Metal-capable capability facts" >&2
      exit 12
    fi
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: unexpected smoke classification $smoke_classification" >&2
    exit 13
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: protected path modified" >&2
  exit 14
fi

{
  echo "rerun_contract_version=1"
  echo "capability_detector_passed=true"
  echo "capability_log=$CAPABILITY_LOG"
  echo "capability_packet=$capability_packet"
  echo "source_handoff_packet=$handoff_packet"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "code_failure_domain=false"
  echo "external_handoff_required=$external_handoff_required"
  echo "external_metal_capable_shell_required=$external_metal_capable_shell_required"
  echo "metal_capable_shell_observed=$metal_capable_shell_observed"
  echo "required_next_actor=human_operator"
  echo "required_shell=metal_capable_shell"
  echo "required_explicit_approval=true"
  echo "required_approval_env=CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED=true"
  echo "automation_must_not_set_approval=true"
  echo "automation_can_continue_non_d3_recovery=$automation_can_continue_non_d3_recovery"
  echo "contract_route=$contract_route"
  echo "contract_waiting_on=$contract_waiting_on"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$RERUN_CONTRACT"

required_contract_facts=(
  "rerun_contract_version=1"
  "capability_detector_passed=true"
  "code_failure_domain=false"
  "required_next_actor=human_operator"
  "required_shell=metal_capable_shell"
  "required_explicit_approval=true"
  "automation_must_not_set_approval=true"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_contract_facts[@]}"; do
  if ! grep -F "$fact" "$RERUN_CONTRACT" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: missing contract fact $fact" >&2
    exit 15
  fi
done

echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: route_classification=runtime_native_probe_handoff_rerun_contract"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: capability_detector_passed=true"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: rerun_contract_created=true"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: rerun_contract_path=$RERUN_CONTRACT"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: capability_packet=$capability_packet"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: source_handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: external_handoff_required=$external_handoff_required"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: external_metal_capable_shell_required=$external_metal_capable_shell_required"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: metal_capable_shell_observed=$metal_capable_shell_observed"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: required_shell=metal_capable_shell"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: required_explicit_approval=true"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: automation_can_continue_non_d3_recovery=$automation_can_continue_non_d3_recovery"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe handoff rerun contract: next_route=related_regression_guard_aggregation_or_human_approved_d3_execution"
