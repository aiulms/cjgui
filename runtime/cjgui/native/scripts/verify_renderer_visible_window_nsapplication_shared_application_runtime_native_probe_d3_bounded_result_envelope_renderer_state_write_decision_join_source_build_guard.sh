#!/usr/bin/env zsh
#
# 维护注释：本脚本为 stage104 bounded admission + independent write-decision
# join preflight 提供 source/build/probe guard。默认使用 fixture-only admitted
# envelope 验证正向 join 形状，不执行 runtime native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-renderer-state-write-decision-join-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_owner.sh"
FIXTURE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_admitted_fixture.sh"
JOIN_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_classifier.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join.cj"
OWNER_LOG="$TMP_DIR/owner.log"
FIXTURE_LOG="$TMP_DIR/fixture.log"
JOIN_LOG="$TMP_DIR/join.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-result-envelope-renderer-state-write-decision-join-source-build.packet"
JOIN_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_PACKET:-}"
CLASSIFIER_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_CLASSIFIER_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$FIXTURE_LOG"
: > "$JOIN_LOG"
: > "$CLASSIFIER_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$FIXTURE_SCRIPT" "$JOIN_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: missing executable script $script" >&2
    exit 3
  fi
done

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

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: log=$OWNER_LOG" >&2
  exit 4
fi

required_owner_facts=(
  "d3_bounded_result_envelope_renderer_state_write_decision_join_owner_present=true"
  "admitted_bounded_result_envelope_input_required=true"
  "independent_write_decision_contract_input_required=true"
  "guarded_write_decision_join_preflight_route=true"
  "bounded_envelope_remains_isolated_evidence_only=true"
  "write_decision_contract_is_not_write_permission=true"
  "production_write_admission_after_join_preflight_required=true"
  "renderer_state_write_after_join_preflight_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: missing owner fact $fact" >&2
    exit 5
  fi
done

fixture_packet=""
if [[ -z "$JOIN_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/fixture" zsh "$FIXTURE_SCRIPT" > "$FIXTURE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: admitted fixture failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: log=$FIXTURE_LOG" >&2
    exit 6
  fi
  fixture_packet="$(grep -Eo 'fixture_packet_path=[^[:space:]]+' "$FIXTURE_LOG" | tail -1 | cut -d= -f2-)"
  if [[ -z "$fixture_packet" || ! -f "$fixture_packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: missing fixture packet" >&2
    exit 7
  fi
  if ! env TMPDIR="$TMP_DIR/join" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SUITE_PACKET="$fixture_packet" zsh "$JOIN_PACKET_SCRIPT" > "$JOIN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: join packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: log=$JOIN_LOG" >&2
    exit 8
  fi
  JOIN_PACKET="$(grep -Eo 'join_packet_path=[^[:space:]]+' "$JOIN_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$JOIN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: provided join packet missing $JOIN_PACKET" >&2
    exit 9
  fi
  {
    echo "provided_join_packet_used=true"
    echo "join_packet_path=$JOIN_PACKET"
  } > "$JOIN_LOG"
fi

if [[ -z "$JOIN_PACKET" || ! -f "$JOIN_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: missing join packet" >&2
  exit 10
fi

if [[ -z "$CLASSIFIER_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/classifier" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_PACKET="$JOIN_PACKET" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: log=$CLASSIFIER_LOG" >&2
    exit 11
  fi
  CLASSIFIER_PACKET="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: provided classifier packet missing $CLASSIFIER_PACKET" >&2
    exit 12
  fi
  {
    echo "provided_classifier_packet_used=true"
    echo "classifier_packet_path=$CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
fi

required_join_facts=(
  "d3_bounded_result_envelope_renderer_state_write_decision_join_packet_passed=true"
  "guarded_write_decision_join_preflight_ready=true"
  "renderer_state_write_after_join_preflight_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_join_facts[@]}"; do
  if ! grep -F "$fact" "$JOIN_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: missing join fact $fact" >&2
    exit 13
  fi
done

required_classifier_facts=(
  "d3_bounded_result_envelope_renderer_state_write_decision_join_classifier_passed=true"
  "guarded_write_decision_join_preflight_ready=true"
  "join_preflight_is_not_renderer_state_write_permission=true"
  "production_write_admission_after_join_preflight_required=true"
  "renderer_state_write_after_join_preflight_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: missing classifier fact $fact" >&2
    exit 14
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: public or foreign declaration found in owner" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: public or foreign declaration diff found" >&2
  exit 16
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: forbidden application/visible/render token found in owner" >&2
  exit 17
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: forbidden production native bridge diff found" >&2
  exit 18
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: protected path modified" >&2
  exit 19
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: cjpm unavailable" >&2
  exit 20
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: log=$BUILD_LOG" >&2
  exit 21
fi

{
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_source_build_guard_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "fixture_log=$FIXTURE_LOG"
  echo "fixture_packet=$fixture_packet"
  echo "join_log=$JOIN_LOG"
  echo "join_packet=$JOIN_PACKET"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$CLASSIFIER_PACKET"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_fixture_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_packet_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_classifier_passed=true"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "source_build_join_guard_passed=true"
  echo "guarded_write_decision_join_preflight_ready=true"
  echo "join_preflight_is_not_renderer_state_write_permission=true"
  echo "production_write_admission_after_join_preflight_required=true"
  echo "renderer_state_write_after_join_preflight_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: route_classification=d3_bounded_result_envelope_renderer_state_write_decision_join_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: d3_bounded_result_envelope_renderer_state_write_decision_join_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: d3_bounded_result_envelope_renderer_state_write_decision_join_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: d3_bounded_result_envelope_renderer_state_write_decision_join_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: guarded_write_decision_join_preflight_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: renderer_state_write_after_join_preflight_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join source build guard: renderer_state_write=false"
