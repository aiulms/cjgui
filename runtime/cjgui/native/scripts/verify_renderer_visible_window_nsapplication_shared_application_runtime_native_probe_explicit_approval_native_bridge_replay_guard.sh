#!/usr/bin/env zsh
#
# 维护注释：本脚本重跑 explicit approval route-scoped native bridge evidence，
# 再追加 native bridge package-link probe，确认 route-scoped evidence 没有扩张为
# runtime native execution 或 production bridge mutation。
# Truth: route-scoped native bridge evidence strengthening；不新增或修改 native
# bridge surface，不执行 runtime native probe，不消费 D3 approval，不调用
# application accessor，不创建 singleton。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-native-bridge-replay"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
ROUTE_NATIVE_EVIDENCE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_route_scoped_native_bridge_evidence.sh"
PACKAGE_LINK_PROBE="$SCRIPT_DIR/verify_native_bridge_cjpm_package_link_probe.sh"
NATIVE_LOG="$TMP_DIR/route-scoped-native-evidence.log"
PACKAGE_LINK_LOG="$TMP_DIR/native-bridge-package-link.log"
REPLAY_PACKET="$TMP_DIR/explicit-approval-native-bridge-replay.packet"
PACKAGE_LINK_TMP_DIR="$TMP_DIR/nested-package-link"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$PACKAGE_LINK_TMP_DIR"
: > "$NATIVE_LOG"
: > "$PACKAGE_LINK_LOG"
: > "$REPLAY_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$ROUTE_NATIVE_EVIDENCE" "$PACKAGE_LINK_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-native" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$ROUTE_NATIVE_EVIDENCE" > "$NATIVE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: route-scoped native evidence failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: log=$NATIVE_LOG" >&2
  exit 5
fi

required_native_facts=(
  "route_classification=runtime_native_probe_route_scoped_native_bridge_evidence"
  "approval_gate_packet_passed=true"
  "native_skeleton_compile_passed=true"
  "native_no_resource_symbols_passed=true"
  "route_scoped_native_bridge_evidence_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_native_facts[@]}"; do
  if ! grep -F "$fact" "$NATIVE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: missing native fact $fact" >&2
    exit 6
  fi
done

if ! env TMPDIR="$PACKAGE_LINK_TMP_DIR" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" PATH="$PS_SHIM_DIR:$PATH" zsh "$PACKAGE_LINK_PROBE" > "$PACKAGE_LINK_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: package link probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: log=$PACKAGE_LINK_LOG" >&2
  exit 7
fi
if ! grep -F "temporary_cjpm_package_linked=true" "$PACKAGE_LINK_LOG" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: missing package link marker" >&2
  exit 8
fi
if ! grep -F "runtime_package_config_modified=false" "$PACKAGE_LINK_LOG" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: missing runtime package config marker" >&2
  exit 9
fi

native_packet="$(grep -Eo 'native_evidence_packet_path=[^[:space:]]+' "$NATIVE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$native_packet" || ! -f "$native_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: missing native packet" >&2
  exit 10
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$native_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$native_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$native_packet" | tail -1 | cut -d= -f2)"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: protected path modified" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: forbidden production native bridge diff found" >&2
  exit 12
fi

{
  echo "explicit_approval_native_bridge_replay_version=1"
  echo "route_scoped_native_bridge_evidence_passed=true"
  echo "native_log=$NATIVE_LOG"
  echo "native_packet=$native_packet"
  echo "native_bridge_package_link_probe_passed=true"
  echo "package_link_log=$PACKAGE_LINK_LOG"
  echo "temporary_cjpm_package_linked=true"
  echo "runtime_package_config_modified=false"
  echo "native_bridge_replay_guard_passed=true"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
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
} > "$REPLAY_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: route_classification=runtime_native_probe_explicit_approval_native_bridge_replay_guard"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: route_scoped_native_bridge_evidence_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: native_bridge_package_link_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: native_bridge_replay_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: replay_packet_path=$REPLAY_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: native_packet=$native_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval native bridge replay guard: renderer_state_write=false"
