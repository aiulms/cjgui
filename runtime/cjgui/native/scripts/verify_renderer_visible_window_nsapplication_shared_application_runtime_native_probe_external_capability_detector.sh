#!/usr/bin/env zsh
#
# 维护注释：本脚本为 runtime native-readiness probe 的 external handoff
# 增加 capability detector。它重跑 stage85 external handoff classification，
# 读取 temporary handoff packet，并把当前 automation shell 的工具链、Metal
# smoke 分类与 D3 approval 状态整理为可复核 capability packet。
# Truth: 这是 probe/script 层 capability detector；不新增 runtime readiness
# owner，不执行 runtime native probe，不调用 production application singleton
# accessor，不创建 singleton，不扩 native bridge，不消费 human approval，不升级
# production ownership truth。
# Stop-line: 不调用 production sharedApplication accessor，不创建或激活
# NSApplication，不修改 activation policy，不运行 AppKit event loop / bounded
# pump，不执行 cleanup / teardown，不创建 visible window，不 visible order，不取
# nextDrawable，不 render / commit / present / GPU submission，不改 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-external-capability-detector"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
HANDOFF_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_handoff_classification.sh"
HANDOFF_LOG="$TMP_DIR/external-handoff-classification.log"
CAPABILITY_PACKET="$TMP_DIR/runtime-native-probe-external-capability.packet"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR"
: > "$HANDOFF_LOG"
: > "$CAPABILITY_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

if [[ ! -x "$HANDOFF_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe external capability detector: missing executable handoff script $HANDOFF_SCRIPT" >&2
  exit 3
fi

if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe external capability detector: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$HANDOFF_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe external capability detector: stage85 external handoff classification failed" >&2
  echo "cjgui renderer NSApplication runtime native probe external capability detector: log=$HANDOFF_LOG" >&2
  exit 5
fi

required_handoff_facts=(
  "route_classification=external_handoff_failure_domain_classification"
  "stage84_failure_domain_guard_passed=true"
  "handoff_packet_created=true"
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

for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$HANDOFF_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe external capability detector: missing handoff fact $fact" >&2
    exit 6
  fi
done

handoff_packet="$(grep -Eo 'handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe external capability detector: missing handoff packet" >&2
  exit 7
fi

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
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe external capability detector: missing handoff packet fact $fact" >&2
    exit 8
  fi
done

ensure_toolchain_optional() {
  if command -v cjpm >/dev/null 2>&1 && command -v cjc >/dev/null 2>&1; then
    return
  fi
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    export PATH="$PS_SHIM_DIR:$PATH"
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
}

ensure_toolchain_optional

cjpm_available="false"
cjc_available="false"
clang_available="false"
xcrun_available="false"
system_profiler_available="false"
auto_close_smoke_available="false"
d3_approval_env_present="false"
d3_approval_env_true="false"

if command -v cjpm >/dev/null 2>&1; then
  cjpm_available="true"
fi
if command -v cjc >/dev/null 2>&1; then
  cjc_available="true"
fi
if command -v clang >/dev/null 2>&1; then
  clang_available="true"
fi
if command -v xcrun >/dev/null 2>&1; then
  xcrun_available="true"
fi
if command -v system_profiler >/dev/null 2>&1; then
  system_profiler_available="true"
fi
if [[ -x "$REPO_DIR/labs/macos_bridge_smoke/scripts/verify_auto_close.sh" ]]; then
  auto_close_smoke_available="true"
fi
if [[ -n "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" ]]; then
  d3_approval_env_present="true"
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  d3_approval_env_true="true"
fi

smoke_classification="$(grep -Eo 'smoke_environment_classification=[A-Za-z0-9_]+' "$handoff_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo 'smoke_exit_code=[0-9]+' "$handoff_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$handoff_packet" | tail -1 | cut -d= -f2)"
external_handoff_required="$(grep -Eo '^external_handoff_required=(true|false)' "$handoff_packet" | tail -1 | cut -d= -f2)"
external_metal_capable_shell_required="$(grep -Eo '^external_metal_capable_shell_required=(true|false)' "$handoff_packet" | tail -1 | cut -d= -f2)"
automation_environment_blocker_reconfirmed="$(grep -Eo '^automation_environment_blocker_reconfirmed=(true|false)' "$handoff_packet" | tail -1 | cut -d= -f2)"
metal_capable_shell_observed="$(grep -Eo '^metal_capable_shell_observed=(true|false)' "$handoff_packet" | tail -1 | cut -d= -f2)"

case "$smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" || "$failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe external capability detector: inconsistent Metal-unavailable facts" >&2
      exit 9
    fi
    ;;
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" || "$metal_capable_shell_observed" != "true" ]]; then
      echo "cjgui renderer NSApplication runtime native probe external capability detector: inconsistent Metal-capable facts" >&2
      exit 10
    fi
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe external capability detector: unexpected smoke classification $smoke_classification" >&2
    exit 11
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe external capability detector: protected path modified" >&2
  exit 12
fi

{
  echo "capability_packet_version=1"
  echo "external_handoff_classification_passed=true"
  echo "handoff_log=$HANDOFF_LOG"
  echo "handoff_packet=$handoff_packet"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "code_failure_domain=false"
  echo "external_handoff_required=$external_handoff_required"
  echo "external_metal_capable_shell_required=$external_metal_capable_shell_required"
  echo "automation_environment_blocker_reconfirmed=$automation_environment_blocker_reconfirmed"
  echo "metal_capable_shell_observed=$metal_capable_shell_observed"
  echo "cjpm_available=$cjpm_available"
  echo "cjc_available=$cjc_available"
  echo "clang_available=$clang_available"
  echo "xcrun_available=$xcrun_available"
  echo "system_profiler_available=$system_profiler_available"
  echo "auto_close_smoke_available=$auto_close_smoke_available"
  echo "d3_approval_env_present=$d3_approval_env_present"
  echo "d3_approval_env_true=$d3_approval_env_true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
} > "$CAPABILITY_PACKET"

required_capability_facts=(
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

for fact in "${required_capability_facts[@]}"; do
  if ! grep -F "$fact" "$CAPABILITY_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe external capability detector: missing capability packet fact $fact" >&2
    exit 13
  fi
done

echo "cjgui renderer NSApplication runtime native probe external capability detector: route_classification=runtime_native_probe_external_capability_detector"
echo "cjgui renderer NSApplication runtime native probe external capability detector: external_handoff_classification_passed=true"
echo "cjgui renderer NSApplication runtime native probe external capability detector: capability_packet_created=true"
echo "cjgui renderer NSApplication runtime native probe external capability detector: capability_packet_path=$CAPABILITY_PACKET"
echo "cjgui renderer NSApplication runtime native probe external capability detector: handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe external capability detector: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe external capability detector: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe external capability detector: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe external capability detector: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: external_handoff_required=$external_handoff_required"
echo "cjgui renderer NSApplication runtime native probe external capability detector: external_metal_capable_shell_required=$external_metal_capable_shell_required"
echo "cjgui renderer NSApplication runtime native probe external capability detector: automation_environment_blocker_reconfirmed=$automation_environment_blocker_reconfirmed"
echo "cjgui renderer NSApplication runtime native probe external capability detector: metal_capable_shell_observed=$metal_capable_shell_observed"
echo "cjgui renderer NSApplication runtime native probe external capability detector: cjpm_available=$cjpm_available"
echo "cjgui renderer NSApplication runtime native probe external capability detector: cjc_available=$cjc_available"
echo "cjgui renderer NSApplication runtime native probe external capability detector: clang_available=$clang_available"
echo "cjgui renderer NSApplication runtime native probe external capability detector: xcrun_available=$xcrun_available"
echo "cjgui renderer NSApplication runtime native probe external capability detector: system_profiler_available=$system_profiler_available"
echo "cjgui renderer NSApplication runtime native probe external capability detector: auto_close_smoke_available=$auto_close_smoke_available"
echo "cjgui renderer NSApplication runtime native probe external capability detector: d3_approval_env_present=$d3_approval_env_present"
echo "cjgui renderer NSApplication runtime native probe external capability detector: d3_approval_env_true=$d3_approval_env_true"
echo "cjgui renderer NSApplication runtime native probe external capability detector: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe external capability detector: next_route=handoff_rerun_contract_without_runtime_native_probe_execution"
