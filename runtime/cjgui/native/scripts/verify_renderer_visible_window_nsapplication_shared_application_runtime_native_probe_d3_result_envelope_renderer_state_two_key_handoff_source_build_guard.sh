#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 result-envelope renderer-state two-key handoff 提供
# source/build/probe guard。它串联 owner、handoff packet、matrix 与 runtime
# package build。
# Truth: source/build/probe two-key handoff guard；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩
# native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-two-key-handoff-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_owner.sh"
HANDOFF_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_packet.sh"
MATRIX_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff_matrix.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_two_key_handoff.cj"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-owner.log"
HANDOFF_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff.log"
MATRIX_LOG="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-matrix.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-two-key-handoff-source-build.packet"
BUILD_TARGET_DIR="$TMP_DIR/target"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
EXTERNAL_HANDOFF_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TWO_KEY_HANDOFF_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_TARGET_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$HANDOFF_LOG"
: > "$MATRIX_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$HANDOFF_PACKET_SCRIPT" "$MATRIX_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: current guard route must not consume D3 approval" >&2
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
    # shellcheck disable=SC1091
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
}

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: cjc unavailable" >&2
  exit 6
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_owner_present=true"
  "write_decision_contract_input=true"
  "external_provenance_packet_slot_bound=true"
  "independent_write_decision_packet_slot_bound=true"
  "packet_path_artifact_handoff_required=true"
  "external_shell_produced_provenance_packet_required=true"
  "current_shell_two_key_join_dehydrated=true"
  "synthetic_packet_admission_denied=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_HANDOFF_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_HANDOFF_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: external handoff packet missing $EXTERNAL_HANDOFF_PACKET" >&2
    exit 9
  fi
  {
    echo "external_two_key_handoff_packet_used=true"
    echo "two_key_handoff_packet_path=$EXTERNAL_HANDOFF_PACKET"
    cat "$EXTERNAL_HANDOFF_PACKET"
  } > "$HANDOFF_LOG"
else
  SHORT_HANDOFF_TMP="/tmp/cjgui-stage101-source-two-key-handoff-${$}"
  mkdir -p "$SHORT_HANDOFF_TMP"
  if ! env TMPDIR="$SHORT_HANDOFF_TMP" zsh "$HANDOFF_PACKET_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: handoff packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: log=$HANDOFF_LOG" >&2
    exit 10
  fi
fi

handoff_packet="${EXTERNAL_HANDOFF_PACKET:-$(grep -Eo 'two_key_handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: missing handoff packet $handoff_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-matrix" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TWO_KEY_HANDOFF_PACKET="$handoff_packet" zsh "$MATRIX_SCRIPT" > "$MATRIX_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: matrix failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: log=$MATRIX_LOG" >&2
  exit 12
fi
matrix_packet="$(grep -Eo 'two_key_handoff_matrix_packet_path=[^[:space:]]+' "$MATRIX_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$matrix_packet" || ! -f "$matrix_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: missing matrix packet $matrix_packet" >&2
  exit 13
fi

required_downstream_facts=(
  "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
  "d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
  "two_key_handoff_carrier_ready=true"
  "external_provenance_packet_slot_bound=true"
  "independent_write_decision_packet_slot_bound=true"
  "synthetic_both_key_case_admitted=false"
  "renderer_state_write_after_two_key_handoff_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_downstream_facts[@]}"; do
  if ! grep -F "$fact" "$handoff_packet" "$matrix_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: missing downstream fact $fact" >&2
    exit 14
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: log=$BUILD_LOG" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: protected path modified" >&2
  exit 16
fi

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: public or foreign declaration found in owner" >&2
  exit 17
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: forbidden application/visible/render token found in owner" >&2
  exit 18
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: forbidden production native bridge diff found" >&2
  exit 19
fi

{
  echo "d3_result_envelope_renderer_state_two_key_handoff_source_build_guard_version=1"
  echo "d3_result_envelope_renderer_state_two_key_handoff_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
  echo "handoff_log=$HANDOFF_LOG"
  echo "two_key_handoff_packet=$handoff_packet"
  echo "d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
  echo "matrix_log=$MATRIX_LOG"
  echo "two_key_handoff_matrix_packet=$matrix_packet"
  echo "runtime_package_build_passed=true"
  echo "source_build_two_key_handoff_guard_passed=true"
  echo "two_key_handoff_carrier_ready=true"
  echo "two_key_handoff_ready_for_external_shell=true"
  echo "renderer_state_write_after_two_key_handoff_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
  echo "failure_domain=automation_environment"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: route_classification=d3_result_envelope_renderer_state_two_key_handoff_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: d3_result_envelope_renderer_state_two_key_handoff_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: d3_result_envelope_renderer_state_two_key_handoff_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: d3_result_envelope_renderer_state_two_key_handoff_matrix_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: source_build_two_key_handoff_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state two-key handoff source build guard: human_approved_d3_execution_consumed=false"
