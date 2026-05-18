#!/usr/bin/env zsh
#
# 维护注释：本脚本串联 D3 bounded runtime execution owner、environment
# packet、result envelope semantics、result envelope 与 runtime package build。
# Stop-line: 当前非 Metal shell 下不执行 native probe；Metal-capable 时只允许
# result-envelope script 执行 isolated visible-window probe，不写 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-runtime-execution-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_owner.sh"
ENVIRONMENT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_environment_packet.sh"
RESULT_ENVELOPE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_result_envelope.sh"
SEMANTICS_SCRIPT="$SCRIPT_DIR/verify_native_bridge_drawable_visible_window_environment_result_envelope_semantics.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution.cj"
OWNER_LOG="$TMP_DIR/owner.log"
ENVIRONMENT_LOG="$TMP_DIR/environment.log"
RESULT_ENVELOPE_LOG="$TMP_DIR/result-envelope.log"
SEMANTICS_LOG="$TMP_DIR/semantics.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-runtime-execution-source-build.packet"
ENVIRONMENT_PACKET="${CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_ENVIRONMENT_PACKET:-}"
RESULT_ENVELOPE="${CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$ENVIRONMENT_LOG"
: > "$RESULT_ENVELOPE_LOG"
: > "$SEMANTICS_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$ENVIRONMENT_PACKET_SCRIPT" "$RESULT_ENVELOPE_SCRIPT" "$SEMANTICS_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: missing executable script $script" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: log=$OWNER_LOG" >&2
  exit 4
fi

if ! zsh "$SEMANTICS_SCRIPT" > "$SEMANTICS_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: result envelope semantics failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: log=$SEMANTICS_LOG" >&2
  exit 5
fi

if [[ -z "$ENVIRONMENT_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/environment" zsh "$ENVIRONMENT_PACKET_SCRIPT" > "$ENVIRONMENT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: environment packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: log=$ENVIRONMENT_LOG" >&2
    exit 6
  fi
  ENVIRONMENT_PACKET="$(grep -Eo 'environment_packet_path=[^[:space:]]+' "$ENVIRONMENT_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$ENVIRONMENT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: provided environment packet missing $ENVIRONMENT_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_environment_packet_used=true"
    echo "environment_packet_path=$ENVIRONMENT_PACKET"
  } > "$ENVIRONMENT_LOG"
fi

if [[ -z "$RESULT_ENVELOPE" ]]; then
  if ! env TMPDIR="$TMP_DIR/result-envelope" CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_ENVIRONMENT_PACKET="$ENVIRONMENT_PACKET" zsh "$RESULT_ENVELOPE_SCRIPT" > "$RESULT_ENVELOPE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: result envelope failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: log=$RESULT_ENVELOPE_LOG" >&2
    exit 8
  fi
  RESULT_ENVELOPE="$(grep -Eo 'result_envelope_path=[^[:space:]]+' "$RESULT_ENVELOPE_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$RESULT_ENVELOPE" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: provided result envelope missing $RESULT_ENVELOPE" >&2
    exit 9
  fi
  {
    echo "provided_result_envelope_used=true"
    echo "result_envelope_path=$RESULT_ENVELOPE"
  } > "$RESULT_ENVELOPE_LOG"
fi

required_owner_facts=(
  "d3_bounded_runtime_execution_owner_present=true"
  "two_key_handoff_input=true"
  "capability_detector_before_execution_required=true"
  "automation_standing_d3_autonomy_bounded=true"
  "isolated_visible_window_probe_only=true"
  "result_envelope_required=true"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: missing owner fact $fact" >&2
    exit 10
  fi
done

required_result_facts=(
  "d3_bounded_runtime_execution_result_envelope_version=1"
  "result_envelope_semantics_passed=true"
  "result_envelope_is_not_production_truth=true"
  "code_failure_domain=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
)
for fact in "${required_result_facts[@]}"; do
  if ! grep -F "$fact" "$RESULT_ENVELOPE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: missing result fact $fact" >&2
    exit 11
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: public or foreign declaration found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: forbidden production native bridge diff found" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: protected path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: log=$BUILD_LOG" >&2
  exit 16
fi

runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"

{
  echo "d3_bounded_runtime_execution_source_build_guard_version=1"
  echo "d3_bounded_runtime_execution_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_bounded_runtime_execution_environment_packet_passed=true"
  echo "environment_log=$ENVIRONMENT_LOG"
  echo "environment_packet=$ENVIRONMENT_PACKET"
  echo "d3_bounded_runtime_execution_result_envelope_passed=true"
  echo "result_envelope_log=$RESULT_ENVELOPE_LOG"
  echo "result_envelope=$RESULT_ENVELOPE"
  echo "result_envelope_semantics_passed=true"
  echo "runtime_package_build_passed=true"
  echo "source_build_guard_passed=true"
  echo "smoke_environment_classification=$smoke_classification"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: route_classification=d3_bounded_runtime_execution_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: d3_bounded_runtime_execution_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: d3_bounded_runtime_execution_result_envelope_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: runtime_native_probe_execution=$runtime_native_probe_execution"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution source build guard: renderer_state_write=false"
