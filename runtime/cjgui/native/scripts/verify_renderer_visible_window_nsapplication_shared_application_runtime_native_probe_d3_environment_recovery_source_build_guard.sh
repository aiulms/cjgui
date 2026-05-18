#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 environment recovery 提供 source/build/probe evidence。
# 它运行 owner probe、bounded native packet、recovery classifier、runtime package
# build 与 scoped scans。
# Truth: source/build/probe recovery guard；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-environment-recovery-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
BUILD_TARGET_DIR="$TMP_DIR/cjpm-build"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_owner.sh"
NATIVE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_native_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_classifier.sh"
OWNER_LOG="$TMP_DIR/d3-environment-recovery-owner.log"
NATIVE_LOG="$TMP_DIR/d3-environment-recovery-native.log"
CLASSIFIER_LOG="$TMP_DIR/d3-environment-recovery-classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-environment-recovery-source-build-guard.packet"
EXTERNAL_NATIVE_PACKET="${CJGUI_D3_ENVIRONMENT_RECOVERY_NATIVE_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$NATIVE_LOG"
: > "$CLASSIFIER_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$NATIVE_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: current shell is recovery-only and must not consume D3 approval" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: cjc unavailable" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_environment_recovery_owner_present=true"
  "explicit_approval_replay_checkpoint_input=true"
  "current_shell_metal_unavailable=true"
  "failure_domain=automation_environment"
  "external_metal_capable_shell_required=true"
  "d3_limited_approval_unconsumed=true"
  "bounded_native_fail_closed_packet_required=true"
  "recovery_classifier_required=true"
  "source_build_recovery_guard_required=true"
  "focused_recovery_suite_required=true"
  "replay_checkpoint_reusable=true"
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
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_NATIVE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_NATIVE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: external native packet missing $EXTERNAL_NATIVE_PACKET" >&2
    exit 9
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: external_native_packet_used=true"
    echo "route_classification=d3_environment_recovery_native_packet"
    echo "native_packet_path=$EXTERNAL_NATIVE_PACKET"
    cat "$EXTERNAL_NATIVE_PACKET"
  } > "$NATIVE_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-native" zsh "$NATIVE_PACKET_SCRIPT" > "$NATIVE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: native packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: log=$NATIVE_LOG" >&2
    exit 10
  fi
fi

required_native_facts=(
  "bounded_native_fail_closed_packet_ready=true"
  "capability_detector_passed=true"
  "stage93_replay_checkpoint_suite_passed=true"
  "isolated_accessor_disabled_fail_closed=true"
  "throwaway_creation_disabled_fail_closed=true"
  "failure_domain=automation_environment"
  "external_metal_capable_shell_required=true"
  "d3_limited_approval_available_but_unconsumed=true"
  "recovery_route_switch_required=true"
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
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: missing native fact $fact" >&2
    exit 11
  fi
done

native_packet="${EXTERNAL_NATIVE_PACKET:-$(grep -Eo 'native_packet_path=[^[:space:]]+' "$NATIVE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$native_packet" || ! -f "$native_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: missing native packet $native_packet" >&2
  exit 12
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_ENVIRONMENT_RECOVERY_NATIVE_PACKET="$native_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: log=$CLASSIFIER_LOG" >&2
  exit 13
fi

required_classifier_facts=(
  "route_classification=d3_environment_recovery_classifier"
  "d3_execution_precondition_met=false"
  "d3_execution_denied_by_current_environment=true"
  "d3_execution_failure_domain=automation_environment"
  "d3_execution_recovery_route_classified=true"
  "external_metal_capable_shell_required=true"
  "bounded_native_fail_closed_packet_reused=true"
  "stage93_replay_checkpoint_reused=true"
  "d3_limited_approval_available_but_unconsumed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: missing classifier fact $fact" >&2
    exit 14
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: log=$BUILD_LOG" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: protected path modified" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: public or foreign declaration diff found" >&2
  exit 17
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: forbidden production native bridge diff found" >&2
  exit 18
fi

classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: missing classifier packet $classifier_packet" >&2
  exit 19
fi

{
  echo "d3_environment_recovery_source_build_guard_version=1"
  echo "d3_environment_recovery_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "bounded_native_fail_closed_packet_ready=true"
  echo "native_log=$NATIVE_LOG"
  echo "native_packet=$native_packet"
  echo "d3_environment_recovery_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "runtime_package_build_target=$BUILD_TARGET_DIR"
  echo "source_build_recovery_guard_passed=true"
  echo "failure_domain=automation_environment"
  echo "code_failure_domain=false"
  echo "external_metal_capable_shell_required=true"
  echo "metal_capable_shell_observed=false"
  echo "d3_limited_approval_available_but_unconsumed=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: route_classification=d3_environment_recovery_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: d3_environment_recovery_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: bounded_native_fail_closed_packet_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: d3_environment_recovery_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: source_build_recovery_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: native_packet=$native_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: classifier_packet=$classifier_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: failure_domain=automation_environment"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: external_metal_capable_shell_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: metal_capable_shell_observed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: d3_limited_approval_available_but_unconsumed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery source build guard: renderer_state_write=false"
