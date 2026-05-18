#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 result-envelope renderer-state external packet
# provenance replay 提供 source/build/probe guard。它串联 owner、replay packet、
# classifier、write-decision preflight 与 runtime package build。
# Truth: source/build/probe external-packet-provenance-replay guard；不消费 D3
# approval，不执行 runtime native probe，不调用 application accessor，不创建
# singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-provenance-replay-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_owner.sh"
REPLAY_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier.sh"
WRITE_DECISION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay.cj"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-owner.log"
REPLAY_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay.log"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-classifier.log"
WRITE_DECISION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-write-decision.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-source-build.packet"
BUILD_TARGET_DIR="$TMP_DIR/target"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
EXTERNAL_REPLAY_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_TARGET_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$REPLAY_LOG"
: > "$CLASSIFIER_LOG"
: > "$WRITE_DECISION_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$REPLAY_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$WRITE_DECISION_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: current guard route must not consume D3 approval" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: cjc unavailable" >&2
  exit 6
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_present=true"
  "promotion_admission_input=true"
  "external_packet_provenance_replay_route_opened=true"
  "promotion_admission_packet_replay_required=true"
  "external_metal_capable_provenance_replay_required=true"
  "shape_admission_separated_from_provenance_replay=true"
  "current_shell_provenance_replay_denied=true"
  "renderer_state_write_decision_after_external_provenance_required=true"
  "provenance_replay_does_not_write_renderer_state=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_REPLAY_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_REPLAY_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: external replay packet missing $EXTERNAL_REPLAY_PACKET" >&2
    exit 9
  fi
  {
    echo "external_provenance_replay_packet_used=true"
    echo "provenance_replay_packet_path=$EXTERNAL_REPLAY_PACKET"
    cat "$EXTERNAL_REPLAY_PACKET"
  } > "$REPLAY_LOG"
else
  SHORT_REPLAY_TMP="/tmp/cjgui-stage100-source-provenance-replay-${$}"
  mkdir -p "$SHORT_REPLAY_TMP"
  if ! env TMPDIR="$SHORT_REPLAY_TMP" zsh "$REPLAY_PACKET_SCRIPT" > "$REPLAY_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: provenance replay packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: log=$REPLAY_LOG" >&2
    exit 10
  fi
fi

replay_packet="${EXTERNAL_REPLAY_PACKET:-$(grep -Eo 'provenance_replay_packet_path=[^[:space:]]+' "$REPLAY_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$replay_packet" || ! -f "$replay_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing provenance replay packet $replay_packet" >&2
  exit 11
fi

required_replay_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  "external_packet_provenance_replay_ready=true"
  "current_shell_provenance_replay_denied=true"
  "current_shell_provenance_replay_admitted=false"
  "renderer_state_write_decision_after_external_provenance_required=true"
  "runtime_state_line_count_invariant=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_replay_facts[@]}"; do
  if ! grep -F "$fact" "$replay_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing replay fact $fact" >&2
    exit 12
  fi
done

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET="$replay_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: log=$CLASSIFIER_LOG" >&2
  exit 13
fi
classifier_packet="$(grep -Eo 'provenance_replay_classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing classifier packet $classifier_packet" >&2
  exit 14
fi

if ! env TMPDIR="$TMP_DIR/nested-write-decision" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET="$replay_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_CLASSIFIER_PACKET="$classifier_packet" zsh "$WRITE_DECISION_SCRIPT" > "$WRITE_DECISION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: write decision preflight failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: log=$WRITE_DECISION_LOG" >&2
  exit 15
fi
write_decision_packet="$(grep -Eo 'write_decision_preflight_packet_path=[^[:space:]]+' "$WRITE_DECISION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_decision_packet" || ! -f "$write_decision_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing write decision packet $write_decision_packet" >&2
  exit 16
fi

required_downstream_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  "shape_admission_is_not_provenance_truth=true"
  "renderer_state_write_permission_from_replay=false"
  "separate_renderer_state_write_decision_required=true"
  "renderer_state_write_after_provenance_replay_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_downstream_facts[@]}"; do
  if ! grep -F "$fact" "$classifier_packet" "$write_decision_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: missing downstream fact $fact" >&2
    exit 17
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: log=$BUILD_LOG" >&2
  exit 18
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: protected path modified" >&2
  exit 19
fi

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: public or foreign declaration found in owner" >&2
  exit 20
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: forbidden application/visible/render token found in owner" >&2
  exit 21
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: forbidden production native bridge diff found" >&2
  exit 22
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_source_build_guard_version=1"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  echo "replay_log=$REPLAY_LOG"
  echo "provenance_replay_packet=$replay_packet"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "provenance_replay_classifier_packet=$classifier_packet"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  echo "write_decision_log=$WRITE_DECISION_LOG"
  echo "write_decision_preflight_packet=$write_decision_packet"
  echo "runtime_package_build_passed=true"
  echo "source_build_external_packet_provenance_replay_guard_passed=true"
  echo "external_packet_provenance_replay_ready=true"
  echo "current_shell_provenance_replay_admitted=false"
  echo "external_packet_provenance_replay_allowed=false"
  echo "separate_renderer_state_write_decision_required=true"
  echo "renderer_state_write_after_provenance_replay_allowed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: route_classification=d3_result_envelope_renderer_state_external_packet_provenance_replay_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: source_build_external_packet_provenance_replay_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay source build guard: human_approved_d3_execution_consumed=false"
