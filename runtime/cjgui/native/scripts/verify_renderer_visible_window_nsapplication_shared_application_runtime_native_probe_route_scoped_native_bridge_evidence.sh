#!/usr/bin/env zsh
#
# 维护注释：本脚本为 explicit approval handoff route 补 route-scoped native
# bridge evidence。它 fresh rerun approval gate packet，再运行 production native
# skeleton compile 与 no-resource symbol probes。
# Truth: route-scoped native bridge evidence；不新增或修改 native bridge surface，
# 不执行 runtime native probe，不消费 D3 approval，不调用 application accessor，
# 不创建 singleton。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-route-scoped-native-evidence"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
APPROVAL_GATE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_packet.sh"
SKELETON_COMPILE="$SCRIPT_DIR/verify_native_bridge_skeleton_compile.sh"
NO_RESOURCE_SYMBOLS="$SCRIPT_DIR/verify_native_bridge_no_resource_symbols.sh"
APPROVAL_LOG="$TMP_DIR/explicit-approval-gate.log"
SKELETON_LOG="$TMP_DIR/native-skeleton-compile.log"
SYMBOLS_LOG="$TMP_DIR/native-no-resource-symbols.log"
NATIVE_PACKET="$TMP_DIR/route-scoped-native-bridge-evidence.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$APPROVAL_LOG"
: > "$SKELETON_LOG"
: > "$SYMBOLS_LOG"
: > "$NATIVE_PACKET"

for script in "$APPROVAL_GATE" "$SKELETON_COMPILE" "$NO_RESOURCE_SYMBOLS"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-approval" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$APPROVAL_GATE" > "$APPROVAL_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: approval gate packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: log=$APPROVAL_LOG" >&2
  exit 5
fi

required_approval_facts=(
  "route_classification=runtime_native_probe_explicit_approval_gate_packet"
  "approval_packet_created=true"
  "d3_runtime_native_probe_approval_required=true"
  "d3_approval_env_true=false"
  "approved_runtime_native_probe_execution_admitted=false"
  "metal_capable_shell_does_not_imply_approval=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_approval_facts[@]}"; do
  if ! grep -F "$fact" "$APPROVAL_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: missing approval fact $fact" >&2
    exit 6
  fi
done

approval_packet="$(grep -Eo 'approval_packet_path=[^[:space:]]+' "$APPROVAL_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$approval_packet" || ! -f "$approval_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: missing approval packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-skeleton" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$SKELETON_COMPILE" > "$SKELETON_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: native skeleton compile failed" >&2
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: log=$SKELETON_LOG" >&2
  exit 8
fi
if ! grep -F "skeleton compile passed" "$SKELETON_LOG" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: missing skeleton compile pass marker" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-symbols" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$NO_RESOURCE_SYMBOLS" > "$SYMBOLS_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: no-resource symbols probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: log=$SYMBOLS_LOG" >&2
  exit 10
fi
if ! grep -F "no public API, no pointer return, no commit/present/render callable" "$SYMBOLS_LOG" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: missing no-resource symbols pass marker" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: forbidden production native bridge diff found" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: protected path modified" >&2
  exit 13
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$approval_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"

{
  echo "route_scoped_native_bridge_evidence_version=1"
  echo "approval_gate_packet_passed=true"
  echo "approval_log=$APPROVAL_LOG"
  echo "approval_packet=$approval_packet"
  echo "native_skeleton_compile_passed=true"
  echo "skeleton_log=$SKELETON_LOG"
  echo "native_no_resource_symbols_passed=true"
  echo "symbols_log=$SYMBOLS_LOG"
  echo "route_scoped_native_bridge_evidence_passed=true"
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
} > "$NATIVE_PACKET"

echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: route_classification=runtime_native_probe_route_scoped_native_bridge_evidence"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: approval_gate_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: native_skeleton_compile_passed=true"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: native_no_resource_symbols_passed=true"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: route_scoped_native_bridge_evidence_passed=true"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: native_evidence_packet_path=$NATIVE_PACKET"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: approval_packet=$approval_packet"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe route-scoped native bridge evidence: renderer_state_write=false"
