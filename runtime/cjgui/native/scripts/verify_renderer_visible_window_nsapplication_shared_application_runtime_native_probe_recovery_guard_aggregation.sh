#!/usr/bin/env zsh
#
# 维护注释：本脚本聚合 runtime native-readiness probe 的 failure-domain guard、
# external handoff classification、capability detector 与 rerun contract。它用于把
# non-Metal automation recovery 路线收束成一个可重复 guard，而不是继续新增同构
# no-accessor / no-bridge / no-runtime-execution wrapper。
# Truth: 这是 probe/script 层 related regression guards aggregation；不新增 runtime
# readiness owner，不执行 runtime native probe，不调用 production application
# singleton accessor，不创建 singleton，不扩 native bridge，不消费 human approval，
# 不升级 production ownership truth。
# Stop-line: 不调用 production sharedApplication accessor，不创建或激活
# NSApplication，不修改 activation policy，不运行 AppKit event loop / bounded
# pump，不执行 cleanup / teardown，不创建 visible window，不 visible order，不取
# nextDrawable，不 render / commit / present / GPU submission，不改 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-recovery-guard-aggregation"
RERUN_CONTRACT_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_handoff_rerun_contract.sh"
RERUN_CONTRACT_LOG="$TMP_DIR/handoff-rerun-contract.log"
AGGREGATION_PACKET="$TMP_DIR/runtime-native-probe-recovery-guard-aggregation.packet"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$RERUN_CONTRACT_LOG"
: > "$AGGREGATION_PACKET"

if [[ ! -x "$RERUN_CONTRACT_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing executable rerun contract script $RERUN_CONTRACT_SCRIPT" >&2
  exit 3
fi

if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$RERUN_CONTRACT_SCRIPT" > "$RERUN_CONTRACT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: handoff rerun contract failed" >&2
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: log=$RERUN_CONTRACT_LOG" >&2
  exit 5
fi

required_contract_output_facts=(
  "route_classification=runtime_native_probe_handoff_rerun_contract"
  "capability_detector_passed=true"
  "rerun_contract_created=true"
  "code_failure_domain=false"
  "required_next_actor=human_operator"
  "required_shell=metal_capable_shell"
  "required_explicit_approval=true"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_contract_output_facts[@]}"; do
  if ! grep -F "$fact" "$RERUN_CONTRACT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing rerun contract output fact $fact" >&2
    exit 6
  fi
done

rerun_contract="$(grep -Eo 'rerun_contract_path=[^[:space:]]+' "$RERUN_CONTRACT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$rerun_contract" || ! -f "$rerun_contract" ]]; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing rerun contract" >&2
  exit 7
fi

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
  if ! grep -F "$fact" "$rerun_contract" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing rerun contract fact $fact" >&2
    exit 8
  fi
done

capability_packet="$(grep -Eo '^capability_packet=[^[:space:]]+' "$rerun_contract" | tail -1 | cut -d= -f2-)"
handoff_packet="$(grep -Eo '^source_handoff_packet=[^[:space:]]+' "$rerun_contract" | tail -1 | cut -d= -f2-)"
smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$rerun_contract" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$rerun_contract" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$rerun_contract" | tail -1 | cut -d= -f2)"
external_handoff_required="$(grep -Eo '^external_handoff_required=(true|false)' "$rerun_contract" | tail -1 | cut -d= -f2)"
external_metal_capable_shell_required="$(grep -Eo '^external_metal_capable_shell_required=(true|false)' "$rerun_contract" | tail -1 | cut -d= -f2)"

if [[ -z "$capability_packet" || ! -f "$capability_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing capability packet" >&2
  exit 9
fi
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing handoff packet" >&2
  exit 10
fi

for fact in "capability_packet_version=1" "external_handoff_classification_passed=true"; do
  if ! grep -F "$fact" "$capability_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing capability packet fact $fact" >&2
    exit 11
  fi
done

for fact in "handoff_packet_version=1" "stage84_failure_domain_guard_passed=true"; do
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing handoff packet fact $fact" >&2
    exit 12
  fi
done

case "$smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" || "$failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: inconsistent Metal-unavailable aggregate facts" >&2
      exit 13
    fi
    ;;
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" ]]; then
      echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: inconsistent Metal-capable aggregate facts" >&2
      exit 14
    fi
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: unexpected smoke classification $smoke_classification" >&2
    exit 15
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: protected path modified" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: forbidden production native bridge diff found" >&2
  exit 17
fi

{
  echo "aggregation_packet_version=1"
  echo "handoff_rerun_contract_passed=true"
  echo "rerun_contract_log=$RERUN_CONTRACT_LOG"
  echo "rerun_contract=$rerun_contract"
  echo "capability_packet=$capability_packet"
  echo "source_handoff_packet=$handoff_packet"
  echo "failure_domain_guard_nested=true"
  echo "external_handoff_classification_nested=true"
  echo "capability_detector_nested=true"
  echo "related_regression_guards_aggregated=true"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "code_failure_domain=false"
  echo "external_handoff_required=$external_handoff_required"
  echo "external_metal_capable_shell_required=$external_metal_capable_shell_required"
  echo "non_metal_recovery_route_landed=true"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$AGGREGATION_PACKET"

required_aggregation_facts=(
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

for fact in "${required_aggregation_facts[@]}"; do
  if ! grep -F "$fact" "$AGGREGATION_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: missing aggregation packet fact $fact" >&2
    exit 18
  fi
done

echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: route_classification=runtime_native_probe_recovery_guard_aggregation"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: handoff_rerun_contract_passed=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: failure_domain_guard_nested=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: external_handoff_classification_nested=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: capability_detector_nested=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: related_regression_guards_aggregated=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: aggregation_packet_created=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: aggregation_packet_path=$AGGREGATION_PACKET"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: rerun_contract=$rerun_contract"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: capability_packet=$capability_packet"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: source_handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: external_handoff_required=$external_handoff_required"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: external_metal_capable_shell_required=$external_metal_capable_shell_required"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: non_metal_recovery_route_landed=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe recovery guard aggregation: next_route=source_build_probe_evidence_strengthening_or_human_approved_d3_runtime_native_probe_execution"
