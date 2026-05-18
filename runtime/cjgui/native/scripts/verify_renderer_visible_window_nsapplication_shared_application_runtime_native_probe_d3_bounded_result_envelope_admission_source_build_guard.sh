#!/usr/bin/env zsh
#
# 维护注释：本脚本串联 D3 bounded result-envelope admission owner、schema、
# classifier、runtime package build 与 scoped scans。它可以复用 suite 传入的
# result envelope / schema，避免重复 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-admission-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_owner.sh"
SCHEMA_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_schema.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_classifier.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission.cj"
OWNER_LOG="$TMP_DIR/owner.log"
SCHEMA_LOG="$TMP_DIR/schema.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-result-envelope-admission-source-build.packet"
RESULT_ENVELOPE="${CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE:-}"
SCHEMA_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SCHEMA_PACKET:-}"
CLASSIFIER_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_CLASSIFIER_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$SCHEMA_LOG"
: > "$CLASSIFIER_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$SCHEMA_SCRIPT" "$CLASSIFIER_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: missing executable script $script" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: log=$OWNER_LOG" >&2
  exit 4
fi

required_owner_facts=(
  "d3_bounded_result_envelope_admission_owner_present=true"
  "bounded_runtime_execution_input=true"
  "bounded_runtime_execution_result_envelope_required=true"
  "executed_and_passed_result_envelope_required=true"
  "successful_bounded_result_envelope_admission_route=true"
  "skipped_or_failed_result_envelope_rejected=true"
  "isolated_result_envelope_evidence_only=true"
  "result_envelope_is_not_production_truth=true"
  "backend_ready_truth_upgrade=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: missing owner fact $fact" >&2
    exit 5
  fi
done

if [[ -z "$SCHEMA_PACKET" ]]; then
  if [[ -n "$RESULT_ENVELOPE" && ! -f "$RESULT_ENVELOPE" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: provided result envelope missing $RESULT_ENVELOPE" >&2
    exit 6
  fi
  if ! env TMPDIR="$TMP_DIR/schema" CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE="$RESULT_ENVELOPE" zsh "$SCHEMA_SCRIPT" > "$SCHEMA_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: schema failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: log=$SCHEMA_LOG" >&2
    exit 7
  fi
  SCHEMA_PACKET="$(grep -Eo 'schema_packet_path=[^[:space:]]+' "$SCHEMA_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$SCHEMA_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: provided schema packet missing $SCHEMA_PACKET" >&2
    exit 8
  fi
  {
    echo "provided_schema_packet_used=true"
    echo "schema_packet_path=$SCHEMA_PACKET"
  } > "$SCHEMA_LOG"
fi

if [[ -z "$SCHEMA_PACKET" || ! -f "$SCHEMA_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: missing schema packet" >&2
  exit 9
fi

if [[ -z "$CLASSIFIER_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/classifier" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SCHEMA_PACKET="$SCHEMA_PACKET" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: log=$CLASSIFIER_LOG" >&2
    exit 10
  fi
  CLASSIFIER_PACKET="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: provided classifier packet missing $CLASSIFIER_PACKET" >&2
    exit 11
  fi
  {
    echo "provided_classifier_packet_used=true"
    echo "classifier_packet_path=$CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
fi

required_schema_facts=(
  "bounded_result_envelope_schema_valid=true"
  "result_envelope_isolated_evidence_only=true"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_schema_facts[@]}"; do
  if ! grep -F "$fact" "$SCHEMA_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: missing schema fact $fact" >&2
    exit 12
  fi
done

required_classifier_facts=(
  "bounded_result_envelope_admission_classifier_passed=true"
  "bounded_result_envelope_schema_valid=true"
  "result_envelope_promoted_to_production_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write_after_admission_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: missing classifier fact $fact" >&2
    exit 13
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: public or foreign declaration found in owner" >&2
  exit 14
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: public or foreign declaration diff found" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: forbidden production native bridge diff found" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: log=$BUILD_LOG" >&2
  exit 19
fi

bounded_result_envelope_admitted="$(grep -Eo '^bounded_result_envelope_admitted=(true|false)' "$CLASSIFIER_PACKET" | tail -1 | cut -d= -f2)"
runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$CLASSIFIER_PACKET" | tail -1 | cut -d= -f2)"

{
  echo "d3_bounded_result_envelope_admission_source_build_guard_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "schema_log=$SCHEMA_LOG"
  echo "schema_packet=$SCHEMA_PACKET"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$CLASSIFIER_PACKET"
  echo "d3_bounded_result_envelope_admission_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_admission_schema_passed=true"
  echo "d3_bounded_result_envelope_admission_classifier_passed=true"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "source_build_guard_passed=true"
  echo "bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "renderer_state_write_after_admission_allowed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: route_classification=d3_bounded_result_envelope_admission_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: d3_bounded_result_envelope_admission_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: d3_bounded_result_envelope_admission_schema_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: d3_bounded_result_envelope_admission_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: runtime_native_probe_execution=$runtime_native_probe_execution"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission source build guard: renderer_state_write=false"
