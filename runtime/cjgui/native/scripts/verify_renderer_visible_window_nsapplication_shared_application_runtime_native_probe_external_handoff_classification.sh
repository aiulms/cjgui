#!/usr/bin/env zsh
#
# 维护注释：本脚本把 runtime native-readiness probe 的 post-failure-domain
# handoff 状态做成可复核分类。它重跑 stage84 failure-domain guard，生成
# temporary handoff packet，并把 automation Metal 环境约束与 D3 human-approved
# runtime native probe execution 的硬边界分开。
# Truth: 这是 probe/script 层 external handoff classification；不新增 runtime
# readiness owner，不执行 runtime native probe，不调用 production application
# singleton accessor，不创建 singleton，不扩 native bridge，不消费 human
# approval，不升级 production ownership truth。
# Stop-line: 不调用 production sharedApplication accessor，不创建或激活
# NSApplication，不修改 activation policy，不运行 AppKit event loop / bounded
# pump，不执行 cleanup / teardown，不创建 visible window，不 visible order，不取
# nextDrawable，不 render / commit / present / GPU submission，不改 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-external-handoff-classification"
GUARD_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_failure_domain_regression_guard.sh"
GUARD_LOG="$TMP_DIR/failure-domain-guard.log"
HANDOFF_PACKET="$TMP_DIR/runtime-native-probe-external-handoff.packet"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$GUARD_LOG"
: > "$HANDOFF_PACKET"

if [[ ! -x "$GUARD_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe external handoff classification: missing executable guard $GUARD_SCRIPT" >&2
  exit 3
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$GUARD_SCRIPT" > "$GUARD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe external handoff classification: stage84 failure-domain guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe external handoff classification: log=$GUARD_LOG" >&2
  exit 4
fi

required_guard_facts=(
  "route_classification=runtime_native_probe_failure_domain_regression_guard"
  "stage83_environment_classification_passed=true"
  "native_bridge_skeleton_regression_passed=true"
  "native_bridge_no_resource_symbol_regression_passed=true"
  "native_bridge_package_link_regression_passed=true"
  "runtime_package_build_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "next_runtime_native_probe_execution_requires_human_approved_metal_capable_shell=true"
)

for fact in "${required_guard_facts[@]}"; do
  if ! grep -F "$fact" "$GUARD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe external handoff classification: missing guard fact $fact" >&2
    exit 5
  fi
done

smoke_classification="$(grep -Eo 'smoke_environment_classification=[A-Za-z0-9_]+' "$GUARD_LOG" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo 'smoke_exit_code=[0-9]+' "$GUARD_LOG" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '(^|[[:space:]])failure_domain=[A-Za-z0-9_]+' "$GUARD_LOG" | tail -1 | sed 's/^[[:space:]]*//' | cut -d= -f2)"
external_handoff_required="false"
external_metal_capable_shell_required="false"
automation_environment_blocker_reconfirmed="false"
metal_capable_shell_observed="false"

case "$smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" || "$failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe external handoff classification: inconsistent Metal-unavailable guard facts" >&2
      exit 6
    fi
    external_handoff_required="true"
    external_metal_capable_shell_required="true"
    automation_environment_blocker_reconfirmed="true"
    ;;
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" ]]; then
      echo "cjgui renderer NSApplication runtime native probe external handoff classification: inconsistent Metal-capable guard facts" >&2
      exit 7
    fi
    metal_capable_shell_observed="true"
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe external handoff classification: unexpected smoke classification $smoke_classification" >&2
    exit 8
    ;;
esac

if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe external handoff classification: this script does not consume D3 runtime native probe approval" >&2
  exit 9
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe external handoff classification: protected path modified" >&2
  exit 10
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe external handoff classification: forbidden production native bridge diff found" >&2
  exit 11
fi

{
  echo "handoff_packet_version=1"
  echo "stage84_failure_domain_guard_passed=true"
  echo "guard_log=$GUARD_LOG"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "code_failure_domain=false"
  echo "external_handoff_required=$external_handoff_required"
  echo "external_metal_capable_shell_required=$external_metal_capable_shell_required"
  echo "automation_environment_blocker_reconfirmed=$automation_environment_blocker_reconfirmed"
  echo "metal_capable_shell_observed=$metal_capable_shell_observed"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "human_approval_required_before_runtime_native_probe_execution=true"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$HANDOFF_PACKET"

required_packet_facts=(
  "handoff_packet_version=1"
  "stage84_failure_domain_guard_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "human_approval_required_before_runtime_native_probe_execution=true"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_packet_facts[@]}"; do
  if ! grep -F "$fact" "$HANDOFF_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe external handoff classification: missing packet fact $fact" >&2
    exit 12
  fi
done

echo "cjgui renderer NSApplication runtime native probe external handoff classification: route_classification=external_handoff_failure_domain_classification"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: stage84_failure_domain_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: handoff_packet_created=true"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: handoff_packet_path=$HANDOFF_PACKET"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: guard_log=$GUARD_LOG"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: external_handoff_required=$external_handoff_required"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: external_metal_capable_shell_required=$external_metal_capable_shell_required"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: automation_environment_blocker_reconfirmed=$automation_environment_blocker_reconfirmed"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: metal_capable_shell_observed=$metal_capable_shell_observed"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: human_approval_required_before_runtime_native_probe_execution=true"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe external handoff classification: next_route=human_approved_d3_runtime_native_probe_execution_in_metal_capable_shell_or_hold_at_external_handoff_blocker"
