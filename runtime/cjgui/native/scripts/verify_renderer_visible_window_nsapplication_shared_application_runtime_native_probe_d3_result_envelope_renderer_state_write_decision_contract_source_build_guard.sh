#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 result-envelope renderer-state write-decision contract
# 提供 source/build/probe guard。它串联 owner、contract packet、classifier、
# two-key join preflight 与 runtime package build。
# Truth: source/build/probe write-decision-contract guard；不消费 D3 approval，
# 不执行 runtime native probe，不调用 application accessor，不创建 singleton，
# 不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-write-decision-contract-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_owner.sh"
CONTRACT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_classifier.sh"
TWO_KEY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract.cj"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-owner.log"
CONTRACT_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract.log"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-classifier.log"
TWO_KEY_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-two-key.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-source-build.packet"
BUILD_TARGET_DIR="$TMP_DIR/target"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
EXTERNAL_CONTRACT_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_TARGET_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$CONTRACT_LOG"
: > "$CLASSIFIER_LOG"
: > "$TWO_KEY_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$CONTRACT_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$TWO_KEY_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: current guard route must not consume D3 approval" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: cjc unavailable" >&2
  exit 6
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_owner_present=true"
  "provenance_replay_input=true"
  "renderer_state_write_decision_contract_route_opened=true"
  "external_provenance_replay_before_write_decision_required=true"
  "independent_renderer_state_write_decision_packet_required=true"
  "two_key_join_before_renderer_state_write_required=true"
  "current_shell_write_decision_admission_denied=true"
  "provenance_replay_is_not_write_permission=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_CONTRACT_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_CONTRACT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: external contract packet missing $EXTERNAL_CONTRACT_PACKET" >&2
    exit 9
  fi
  {
    echo "external_write_decision_contract_packet_used=true"
    echo "write_decision_contract_packet_path=$EXTERNAL_CONTRACT_PACKET"
    cat "$EXTERNAL_CONTRACT_PACKET"
  } > "$CONTRACT_LOG"
else
  SHORT_CONTRACT_TMP="/tmp/cjgui-stage100-source-write-contract-${$}"
  mkdir -p "$SHORT_CONTRACT_TMP"
  if ! env TMPDIR="$SHORT_CONTRACT_TMP" zsh "$CONTRACT_PACKET_SCRIPT" > "$CONTRACT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: contract packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: log=$CONTRACT_LOG" >&2
    exit 10
  fi
fi

contract_packet="${EXTERNAL_CONTRACT_PACKET:-$(grep -Eo 'write_decision_contract_packet_path=[^[:space:]]+' "$CONTRACT_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$contract_packet" || ! -f "$contract_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: missing contract packet $contract_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET="$contract_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: log=$CLASSIFIER_LOG" >&2
  exit 12
fi
classifier_packet="$(grep -Eo 'write_decision_contract_classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: missing classifier packet $classifier_packet" >&2
  exit 13
fi

if ! env TMPDIR="$TMP_DIR/nested-two-key" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_PACKET="$contract_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_CLASSIFIER_PACKET="$classifier_packet" zsh "$TWO_KEY_SCRIPT" > "$TWO_KEY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: two-key join failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: log=$TWO_KEY_LOG" >&2
  exit 14
fi
two_key_packet="$(grep -Eo 'two_key_join_packet_path=[^[:space:]]+' "$TWO_KEY_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$two_key_packet" || ! -f "$two_key_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: missing two-key packet $two_key_packet" >&2
  exit 15
fi

required_downstream_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  "d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "two_key_renderer_state_write_join_ready=false"
  "renderer_state_write_after_two_key_join_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_downstream_facts[@]}"; do
  if ! grep -F "$fact" "$contract_packet" "$classifier_packet" "$two_key_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: missing downstream fact $fact" >&2
    exit 16
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: log=$BUILD_LOG" >&2
  exit 17
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: protected path modified" >&2
  exit 18
fi

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: public or foreign declaration found in owner" >&2
  exit 19
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: forbidden application/visible/render token found in owner" >&2
  exit 20
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: forbidden production native bridge diff found" >&2
  exit 21
fi

{
  echo "d3_result_envelope_renderer_state_write_decision_contract_source_build_guard_version=1"
  echo "d3_result_envelope_renderer_state_write_decision_contract_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
  echo "contract_log=$CONTRACT_LOG"
  echo "write_decision_contract_packet=$contract_packet"
  echo "d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "write_decision_contract_classifier_packet=$classifier_packet"
  echo "d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
  echo "two_key_log=$TWO_KEY_LOG"
  echo "two_key_join_packet=$two_key_packet"
  echo "runtime_package_build_passed=true"
  echo "source_build_write_decision_contract_guard_passed=true"
  echo "renderer_state_write_decision_contract_ready=true"
  echo "two_key_renderer_state_write_join_ready=false"
  echo "renderer_state_write_after_two_key_join_allowed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: route_classification=d3_result_envelope_renderer_state_write_decision_contract_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: d3_result_envelope_renderer_state_write_decision_contract_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: d3_result_envelope_renderer_state_write_decision_contract_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: d3_result_envelope_renderer_state_write_decision_contract_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: d3_result_envelope_renderer_state_write_decision_contract_two_key_join_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: source_build_write_decision_contract_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state write decision contract source build guard: human_approved_d3_execution_consumed=false"
