#!/usr/bin/env zsh
#
# 维护注释：本脚本为 explicit approval rerun contract 提供 source/build/probe
# evidence。它运行 rerun owner probe、runtime package build 与 scoped scans。
# Truth: source/build/probe evidence strengthening；不执行 runtime native probe，不
# 消费 D3 approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-source-build-guard"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
BUILD_TARGET_DIR="$TMP_DIR/cjpm-build"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract_owner.sh"
OWNER_LOG="$TMP_DIR/rerun-contract-owner.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/explicit-approval-source-build-guard.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

if [[ ! -x "$OWNER_PROBE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: missing executable owner probe $OWNER_PROBE" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

ensure_toolchain() {
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

ensure_toolchain

if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: cjc unavailable" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "explicit_approval_rerun_contract_owner_present=true"
  "explicit_approval_handoff_evidence_mesh_input=true"
  "two_pass_mesh_rerun_contract_required=true"
  "stable_non_d3_approval_facts_required=true"
  "source_build_guard_required=true"
  "evidence_handoff_packet_required=true"
  "focused_regression_suite_required=true"
  "d3_runtime_native_probe_approval_external=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "code_failure_domain=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: log=$BUILD_LOG" >&2
  exit 9
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: protected path modified" >&2
  exit 10
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: public or foreign declaration diff found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: forbidden production native bridge diff found" >&2
  exit 12
fi

{
  echo "explicit_approval_source_build_guard_version=1"
  echo "rerun_contract_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "runtime_package_build_target=$BUILD_TARGET_DIR"
  echo "source_build_guard_passed=true"
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
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: route_classification=runtime_native_probe_explicit_approval_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: rerun_contract_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: source_build_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval source build guard: renderer_state_write=false"
