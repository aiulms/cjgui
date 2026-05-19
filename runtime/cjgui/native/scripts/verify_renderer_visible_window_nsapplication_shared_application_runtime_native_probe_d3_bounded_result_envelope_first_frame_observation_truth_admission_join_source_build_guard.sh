#!/usr/bin/env zsh
#
# 维护注释：本脚本为 stage118 first-frame observation truth-admission join
# 提供 source/build/probe guard。它验证 owner、packet、classifier、runtime
# package build 与 protected/public/forbidden scans。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage118-first-frame-observation-truth-admission-join-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-truth-admission-join-source-build.packet"
JOIN_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_PACKET:-}"
CLASSIFIER_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_CLASSIFIER_PACKET:-}"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$BUILD_LOG"
: > "$SOURCE_BUILD_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: syntax check failed $script" >&2
    exit 4
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

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: log=$OWNER_LOG" >&2
  exit 6
fi

required_owner_facts=(
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner_present=true"
  "first_frame_observation_first_slice_input=true"
  "renderer_state_write_decision_contract_input=true"
  "positive_first_frame_observed_envelope_input_required=true"
  "frame_hash_summary_before_truth_admission_required=true"
  "independent_write_decision_contract_input_required=true"
  "isolated_first_frame_observation_bound_to_write_decision_contract=true"
  "first_frame_observation_remains_isolated_evidence_only=true"
  "truth_admission_join_is_not_production_render_truth=true"
  "production_truth_admission_after_join_preflight_required=true"
  "production_write_admission_after_truth_admission_join_required=true"
  "production_render_truth_after_join_preflight_allowed=false"
  "renderer_state_write_after_truth_admission_join_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$JOIN_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: log=$PACKET_LOG" >&2
    exit 7
  fi
  JOIN_PACKET="$(grep -Eo 'join_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$JOIN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: provided packet missing $JOIN_PACKET" >&2
    exit 8
  fi
  {
    echo "provided_join_packet_used=true"
    echo "join_packet_path=$JOIN_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$JOIN_PACKET" || ! -f "$JOIN_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: missing join packet" >&2
  exit 9
fi

if [[ -z "$CLASSIFIER_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/classifier" \
    CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_PACKET="$JOIN_PACKET" \
    zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: log=$CLASSIFIER_LOG" >&2
    exit 10
  fi
  CLASSIFIER_PACKET="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: provided classifier packet missing $CLASSIFIER_PACKET" >&2
    exit 11
  fi
  {
    echo "provided_classifier_packet_used=true"
    echo "classifier_packet_path=$CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
fi

if [[ -z "$CLASSIFIER_PACKET" || ! -f "$CLASSIFIER_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: missing classifier packet" >&2
  exit 12
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_passed=true"
  "positive_first_frame_observation_input_ready=true"
  "renderer_state_write_decision_contract_ready=true"
  "first_frame_observation_truth_admission_join_preflight_ready=true"
  "isolated_first_frame_observation_bound_to_write_decision_contract=true"
  "truth_admission_join_is_not_production_render_truth=true"
  "production_truth_admission_after_join_preflight_required=true"
  "production_write_admission_after_truth_admission_join_required=true"
  "production_render_truth_after_join_preflight_allowed=false"
  "renderer_state_write_after_truth_admission_join_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$JOIN_PACKET" "$fact"
done

required_classifier_facts=(
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier_passed=true"
  "first_frame_observation_truth_admission_join_classifier_route=admitted_bounded_first_frame_observation_truth_admission_join_preflight"
  "positive_first_frame_observation_input_ready=true"
  "first_frame_observation_truth_admission_join_preflight_ready=true"
  "truth_admission_join_is_not_production_render_truth=true"
  "production_render_truth_after_join_preflight_allowed=false"
  "renderer_state_write_after_truth_admission_join_allowed=false"
  "production_render_truth=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_classifier_facts[@]}"; do
  require_file_fact "$CLASSIFIER_PACKET" "$fact"
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: public or foreign declaration found in owner" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: public or foreign declaration diff found" >&2
  exit 14
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: forbidden application/visible/render/capture token found in owner" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[+][[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: forbidden production native bridge diff found" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: log=$BUILD_LOG" >&2
  exit 19
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_source_build_guard_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "join_packet_log=$PACKET_LOG"
  echo "join_packet=$JOIN_PACKET"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$CLASSIFIER_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier_passed=true"
  echo "source_build_first_frame_observation_truth_admission_join_guard_passed=true"
  echo "runtime_package_build_passed=true"
  grep -E '^current_shell_first_frame_observation_rerun_ready=' "$JOIN_PACKET" | tail -1
  grep -E '^current_shell_first_frame_observation_rerun_failure_classification=' "$JOIN_PACKET" | tail -1
  grep -E '^first_frame_positive_suite_packet_source=' "$JOIN_PACKET" | tail -1
  grep -E '^stage117_current_shell_first_frame_observation_first_slice_ready=' "$JOIN_PACKET" | tail -1
  grep -E '^stage117_bounded_first_frame_observation_first_slice_executed=' "$JOIN_PACKET" | tail -1
  grep -E '^stage117_first_frame_observation_first_slice_failure_classification=' "$JOIN_PACKET" | tail -1
  grep -E '^stage117_first_frame_observation_first_slice_classifier_route=' "$JOIN_PACKET" | tail -1
  grep -E '^first_frame_observed=' "$JOIN_PACKET" | tail -1
  grep -E '^frame_hash_computed=' "$JOIN_PACKET" | tail -1
  grep -E '^frame_hash_nonzero=' "$JOIN_PACKET" | tail -1
  grep -E '^frame_pixel_width=' "$JOIN_PACKET" | tail -1
  grep -E '^frame_pixel_height=' "$JOIN_PACKET" | tail -1
  grep -E '^captured_nonzero_pixel_sample_count=' "$JOIN_PACKET" | tail -1
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  grep -E '^first_frame_observation_truth_admission_join_classifier_route=' "$CLASSIFIER_PACKET" | tail -1
  grep -E '^positive_first_frame_observation_input_ready=' "$JOIN_PACKET" | tail -1
  grep -E '^renderer_state_write_decision_contract_ready=' "$JOIN_PACKET" | tail -1
  grep -E '^first_frame_observation_truth_admission_join_preflight_ready=' "$JOIN_PACKET" | tail -1
  echo "truth_admission_join_is_not_production_render_truth=true"
  echo "production_truth_admission_after_join_preflight_required=true"
  echo "production_write_admission_after_truth_admission_join_required=true"
  echo "production_render_truth_after_join_preflight_allowed=false"
  echo "renderer_state_write_after_truth_admission_join_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: route_classification=d3_bounded_result_envelope_first_frame_observation_truth_admission_join_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join source build guard: runtime_package_build_passed=true"
