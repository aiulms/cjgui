#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 result-envelope packet validation 提供
# source/build/probe evidence。它运行 owner probe、packet validator、
# renderer-state preflight、promotion classifier、runtime package build 与 scoped
# scans。
# Truth: source/build/probe packet-validation guard；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-packet-validation-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
BUILD_TARGET_DIR="$TMP_DIR/cjpm-build"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validation_owner.sh"
VALIDATOR_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validator.sh"
PREFLIGHT_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_preflight.sh"
PROMOTION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_promotion_classifier.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-packet-validation-owner.log"
VALIDATOR_LOG="$TMP_DIR/d3-result-envelope-packet-validator.log"
PREFLIGHT_LOG="$TMP_DIR/d3-result-envelope-renderer-state-preflight.log"
PROMOTION_LOG="$TMP_DIR/d3-result-envelope-promotion-classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-result-envelope-packet-validation-source-build-guard.packet"
EXTERNAL_VALIDATION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$VALIDATOR_LOG"
: > "$PREFLIGHT_LOG"
: > "$PROMOTION_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$VALIDATOR_SCRIPT" "$PREFLIGHT_SCRIPT" "$PROMOTION_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: current guard route must not consume D3 approval" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: cjpm unavailable" >&2
  exit 5
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: cjc unavailable" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: log=$OWNER_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "d3_result_envelope_packet_validation_owner_present=true"
  "d3_result_envelope_admission_input=true"
  "external_packet_before_promotion_required=true"
  "packet_version_and_route_marker_required=true"
  "capability_packet_binding_required=true"
  "approval_consumption_binding_required=true"
  "native_result_classification_required=true"
  "artifact_containment_binding_required=true"
  "failure_domain_continuity_required=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "current_shell_packet_rejected=true"
  "future_external_packet_schema_only=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing owner fact $fact" >&2
    exit 8
  fi
done

if [[ -n "$EXTERNAL_VALIDATION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_VALIDATION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: external validation packet missing $EXTERNAL_VALIDATION_PACKET" >&2
    exit 9
  fi
  {
    echo "external_validation_packet_used=true"
    echo "packet_validation_packet_path=$EXTERNAL_VALIDATION_PACKET"
    cat "$EXTERNAL_VALIDATION_PACKET"
  } > "$VALIDATOR_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-validator" zsh "$VALIDATOR_SCRIPT" > "$VALIDATOR_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: validator failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: log=$VALIDATOR_LOG" >&2
    exit 10
  fi
fi

validation_packet="${EXTERNAL_VALIDATION_PACKET:-$(grep -Eo 'packet_validation_packet_path=[^[:space:]]+' "$VALIDATOR_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$validation_packet" || ! -f "$validation_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing validation packet $validation_packet" >&2
  exit 11
fi

required_validator_facts=(
  "d3_result_envelope_packet_validator_passed=true"
  "packet_version_and_route_marker_validated=true"
  "capability_packet_binding_validated=true"
  "approval_consumption_binding_validated=true"
  "native_result_classification_validated=true"
  "artifact_containment_binding_validated=true"
  "failure_domain_continuity_validated=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "current_shell_packet_rejected=true"
  "future_external_packet_schema_only=true"
  "renderer_state_write=false"
)
for fact in "${required_validator_facts[@]}"; do
  if ! grep -F "$fact" "$validation_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing validation fact $fact" >&2
    exit 12
  fi
done

if ! env TMPDIR="$TMP_DIR/nested-preflight" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" zsh "$PREFLIGHT_SCRIPT" > "$PREFLIGHT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: renderer-state preflight failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: log=$PREFLIGHT_LOG" >&2
  exit 13
fi
preflight_packet="$(grep -Eo 'preflight_packet_path=[^[:space:]]+' "$PREFLIGHT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$preflight_packet" || ! -f "$preflight_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing preflight packet $preflight_packet" >&2
  exit 14
fi

if ! env TMPDIR="$TMP_DIR/nested-promotion" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PREFLIGHT_PACKET="$preflight_packet" zsh "$PROMOTION_SCRIPT" > "$PROMOTION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: promotion classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: log=$PROMOTION_LOG" >&2
  exit 15
fi
promotion_packet="$(grep -Eo 'promotion_packet_path=[^[:space:]]+' "$PROMOTION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$promotion_packet" || ! -f "$promotion_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing promotion packet $promotion_packet" >&2
  exit 16
fi

required_promotion_facts=(
  "packet_promotion_classifier_passed=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "renderer_state_no_write_preflight_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_promotion_facts[@]}"; do
  if ! grep -F "$fact" "$promotion_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: missing promotion fact $fact" >&2
    exit 17
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: log=$BUILD_LOG" >&2
  exit 18
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: protected path modified" >&2
  exit 19
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: public or foreign declaration diff found" >&2
  exit 20
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: forbidden production native bridge diff found" >&2
  exit 21
fi

{
  echo "d3_result_envelope_packet_validation_source_build_guard_version=1"
  echo "d3_result_envelope_packet_validation_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_packet_validator_passed=true"
  echo "validator_log=$VALIDATOR_LOG"
  echo "packet_validation_packet=$validation_packet"
  echo "renderer_state_no_write_preflight_passed=true"
  echo "preflight_log=$PREFLIGHT_LOG"
  echo "renderer_state_preflight_packet=$preflight_packet"
  echo "packet_promotion_classifier_passed=true"
  echo "promotion_log=$PROMOTION_LOG"
  echo "promotion_packet=$promotion_packet"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "runtime_package_build_target=$BUILD_TARGET_DIR"
  echo "source_build_packet_validation_guard_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "current_shell_packet_rejected=true"
  echo "future_external_packet_schema_only=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: route_classification=d3_result_envelope_packet_validation_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: d3_result_envelope_packet_validation_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: d3_result_envelope_packet_validator_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: renderer_state_no_write_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: packet_promotion_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: source_build_packet_validation_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: packet_validation_packet=$validation_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: renderer_state_preflight_packet=$preflight_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: promotion_packet=$promotion_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation source build guard: human_approved_d3_execution_consumed=false"
