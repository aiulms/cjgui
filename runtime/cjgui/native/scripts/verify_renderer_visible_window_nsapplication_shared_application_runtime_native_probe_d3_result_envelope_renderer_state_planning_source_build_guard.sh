#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 result-envelope renderer-state planning 提供
# source/build/probe evidence。它运行 owner probe、plan packet、transition guard、
# quarantine guard、runtime package build 与 scoped scans。
# Truth: source/build/probe renderer-state planning guard；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-planning-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
BUILD_TARGET_DIR="$TMP_DIR/cjpm-build"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_planning_owner.sh"
PLAN_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_plan_packet.sh"
TRANSITION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_guard.sh"
QUARANTINE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_quarantine_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-planning-owner.log"
PLAN_LOG="$TMP_DIR/d3-result-envelope-renderer-state-plan.log"
TRANSITION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition.log"
QUARANTINE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-quarantine.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-planning-source-build-guard.packet"
EXTERNAL_PLAN_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$PLAN_LOG"
: > "$TRANSITION_LOG"
: > "$QUARANTINE_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$PLAN_SCRIPT" "$TRANSITION_SCRIPT" "$QUARANTINE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: current guard route must not consume D3 approval" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: cjc unavailable" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_planning_owner_present=true"
  "packet_validation_input=true"
  "validated_packet_before_renderer_state_plan_required=true"
  "quarantined_packet_as_planning_input_required=true"
  "renderer_state_transition_descriptor_required=true"
  "no_write_gate_before_promotion_required=true"
  "promotion_hold_until_external_validation_required=true"
  "runtime_state_line_count_invariant_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_PLAN_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PLAN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: external plan packet missing $EXTERNAL_PLAN_PACKET" >&2
    exit 9
  fi
  {
    echo "external_plan_packet_used=true"
    echo "renderer_state_plan_packet_path=$EXTERNAL_PLAN_PACKET"
    cat "$EXTERNAL_PLAN_PACKET"
  } > "$PLAN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-plan" zsh "$PLAN_SCRIPT" > "$PLAN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: plan packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: log=$PLAN_LOG" >&2
    exit 10
  fi
fi

plan_packet="${EXTERNAL_PLAN_PACKET:-$(grep -Eo 'renderer_state_plan_packet_path=[^[:space:]]+' "$PLAN_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$plan_packet" || ! -f "$plan_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing plan packet $plan_packet" >&2
  exit 11
fi

required_plan_facts=(
  "d3_result_envelope_renderer_state_plan_packet_passed=true"
  "renderer_state_transition_descriptor_prepared=true"
  "no_write_gate_before_promotion_confirmed=true"
  "promotion_hold_until_external_validation_confirmed=true"
  "runtime_state_line_count_invariant=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "renderer_state_write=false"
)
for fact in "${required_plan_facts[@]}"; do
  if ! grep -F "$fact" "$plan_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing plan fact $fact" >&2
    exit 12
  fi
done

if ! env TMPDIR="$TMP_DIR/nested-transition" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET="$plan_packet" zsh "$TRANSITION_SCRIPT" > "$TRANSITION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: transition guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: log=$TRANSITION_LOG" >&2
  exit 13
fi
transition_packet="$(grep -Eo 'transition_guard_packet_path=[^[:space:]]+' "$TRANSITION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$transition_packet" || ! -f "$transition_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing transition packet $transition_packet" >&2
  exit 14
fi

if ! env TMPDIR="$TMP_DIR/nested-quarantine" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET="$plan_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_GUARD_PACKET="$transition_packet" zsh "$QUARANTINE_SCRIPT" > "$QUARANTINE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: quarantine guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: log=$QUARANTINE_LOG" >&2
  exit 15
fi
quarantine_packet="$(grep -Eo 'quarantine_guard_packet_path=[^[:space:]]+' "$QUARANTINE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$quarantine_packet" || ! -f "$quarantine_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing quarantine packet $quarantine_packet" >&2
  exit 16
fi

required_quarantine_facts=(
  "renderer_state_quarantine_guard_passed=true"
  "external_validated_packet_still_required=true"
  "renderer_state_write_blocked_before_external_promotion=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_quarantine_facts[@]}"; do
  if ! grep -F "$fact" "$quarantine_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: missing quarantine fact $fact" >&2
    exit 17
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: log=$BUILD_LOG" >&2
  exit 18
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: protected path modified" >&2
  exit 19
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: public or foreign declaration diff found" >&2
  exit 20
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: forbidden production native bridge diff found" >&2
  exit 21
fi

{
  echo "d3_result_envelope_renderer_state_planning_source_build_guard_version=1"
  echo "d3_result_envelope_renderer_state_planning_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_plan_packet_passed=true"
  echo "plan_log=$PLAN_LOG"
  echo "renderer_state_plan_packet=$plan_packet"
  echo "d3_result_envelope_renderer_state_transition_guard_passed=true"
  echo "transition_log=$TRANSITION_LOG"
  echo "renderer_state_transition_guard_packet=$transition_packet"
  echo "renderer_state_quarantine_guard_passed=true"
  echo "quarantine_log=$QUARANTINE_LOG"
  echo "renderer_state_quarantine_guard_packet=$quarantine_packet"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "runtime_package_build_target=$BUILD_TARGET_DIR"
  echo "source_build_renderer_state_planning_guard_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "renderer_state_transition_write_allowed=false"
  echo "renderer_state_write_blocked_before_external_promotion=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: route_classification=d3_result_envelope_renderer_state_planning_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: d3_result_envelope_renderer_state_planning_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: d3_result_envelope_renderer_state_plan_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: d3_result_envelope_renderer_state_transition_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: renderer_state_quarantine_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: source_build_renderer_state_planning_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: renderer_state_plan_packet=$plan_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: renderer_state_transition_guard_packet=$transition_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: renderer_state_quarantine_guard_packet=$quarantine_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning source build guard: human_approved_d3_execution_consumed=false"
