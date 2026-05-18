#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 result-envelope renderer-state transition admission
# 提供 source/build/probe guard。它串联 owner、admission packet、write denial、
# external handoff 与 runtime package build。
# Truth: source/build/probe transition-admission guard；不消费 D3 approval，
# 不执行 runtime native probe，不调用 application accessor，不创建 singleton，
# 不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-transition-admission-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_owner.sh"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_packet.sh"
WRITE_DENIAL_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_write_denial_classifier.sh"
HANDOFF_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_external_packet_handoff.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission.cj"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission-owner.log"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission.log"
WRITE_DENIAL_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-write-denial.log"
HANDOFF_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-handoff.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission-source-build.packet"
BUILD_TARGET_DIR="$TMP_DIR/target"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
EXTERNAL_ADMISSION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_TARGET_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$ADMISSION_LOG"
: > "$WRITE_DENIAL_LOG"
: > "$HANDOFF_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$ADMISSION_SCRIPT" "$WRITE_DENIAL_SCRIPT" "$HANDOFF_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: current guard route must not consume D3 approval" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: cjc unavailable" >&2
  exit 6
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_transition_admission_owner_present=true"
  "renderer_state_planning_input=true"
  "dehydrated_renderer_state_transition_candidate_admitted=true"
  "external_validated_packet_before_transition_write_required=true"
  "promotion_quarantine_carry_forward_required=true"
  "no_write_admission_until_promotion_required=true"
  "transition_admission_audit_packet_required=true"
  "runtime_state_line_count_invariant_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_ADMISSION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: external admission packet missing $EXTERNAL_ADMISSION_PACKET" >&2
    exit 9
  fi
  {
    echo "external_admission_packet_used=true"
    echo "transition_admission_packet_path=$EXTERNAL_ADMISSION_PACKET"
    cat "$EXTERNAL_ADMISSION_PACKET"
  } > "$ADMISSION_LOG"
else
  SHORT_ADMISSION_TMP="/tmp/cjgui-stage98-transition-source-admission-${$}"
  mkdir -p "$SHORT_ADMISSION_TMP"
  if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: admission packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: log=$ADMISSION_LOG" >&2
    exit 10
  fi
fi

admission_packet="${EXTERNAL_ADMISSION_PACKET:-$(grep -Eo 'transition_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing admission packet $admission_packet" >&2
  exit 11
fi

required_admission_facts=(
  "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  "dehydrated_renderer_state_transition_candidate_admitted=true"
  "renderer_state_transition_write_admitted=false"
  "external_validated_packet_before_transition_write_required=true"
  "runtime_state_line_count_invariant=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing admission fact $fact" >&2
    exit 12
  fi
done

if ! env TMPDIR="$TMP_DIR/nested-denial" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET="$admission_packet" zsh "$WRITE_DENIAL_SCRIPT" > "$WRITE_DENIAL_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: write denial classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: log=$WRITE_DENIAL_LOG" >&2
  exit 13
fi
write_denial_packet="$(grep -Eo 'write_denial_packet_path=[^[:space:]]+' "$WRITE_DENIAL_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_denial_packet" || ! -f "$write_denial_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing write denial packet $write_denial_packet" >&2
  exit 14
fi

if ! env TMPDIR="$TMP_DIR/nested-handoff" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET="$admission_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_WRITE_DENIAL_PACKET="$write_denial_packet" zsh "$HANDOFF_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: external handoff failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: log=$HANDOFF_LOG" >&2
  exit 15
fi
handoff_packet="$(grep -Eo 'external_packet_handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing handoff packet $handoff_packet" >&2
  exit 16
fi

required_handoff_facts=(
  "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  "external_validated_packet_still_required=true"
  "automation_default_packet_cannot_unlock_renderer_state_write=true"
  "renderer_state_write_blocked_by_admission=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: missing handoff fact $fact" >&2
    exit 17
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: log=$BUILD_LOG" >&2
  exit 18
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: protected path modified" >&2
  exit 19
fi

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: public or foreign declaration found in owner" >&2
  exit 20
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: forbidden application/visible/render token found in owner" >&2
  exit 21
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: forbidden production native bridge diff found" >&2
  exit 22
fi

{
  echo "d3_result_envelope_renderer_state_transition_admission_source_build_guard_version=1"
  echo "d3_result_envelope_renderer_state_transition_admission_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  echo "admission_log=$ADMISSION_LOG"
  echo "transition_admission_packet=$admission_packet"
  echo "d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
  echo "write_denial_log=$WRITE_DENIAL_LOG"
  echo "write_denial_packet=$write_denial_packet"
  echo "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  echo "handoff_log=$HANDOFF_LOG"
  echo "external_packet_handoff_packet=$handoff_packet"
  echo "runtime_package_build_passed=true"
  echo "source_build_transition_admission_guard_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "renderer_state_transition_write_admitted=false"
  echo "renderer_state_write_blocked_by_admission=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: route_classification=d3_result_envelope_renderer_state_transition_admission_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: d3_result_envelope_renderer_state_transition_admission_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: source_build_transition_admission_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission source build guard: human_approved_d3_execution_consumed=false"
