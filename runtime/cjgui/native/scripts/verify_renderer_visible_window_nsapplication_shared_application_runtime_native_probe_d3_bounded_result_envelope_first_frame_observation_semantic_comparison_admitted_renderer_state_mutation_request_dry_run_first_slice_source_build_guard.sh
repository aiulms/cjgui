#!/usr/bin/env zsh
#
# 维护注释：本脚本为 renderer-state mutation request dry-run first slice 提供
# source/build guard。它验证 owner、packet、classifier、扫描与 runtime build。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-source-build.packet"
MUTATION_REQUEST_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_PACKET:-}"
CLASSIFIER_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_CLASSIFIER_PACKET:-}"

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
    echo "cjgui semantic-comparison-admitted mutation request source build guard: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui semantic-comparison-admitted mutation request source build guard: syntax check failed $script" >&2
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
    echo "cjgui semantic-comparison-admitted mutation request source build guard: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: owner probe failed" >&2
  echo "cjgui semantic-comparison-admitted mutation request source build guard: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_owner_present=true" \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true" \
  "renderer_state_mutation_request_shape_defined=true" \
  "decision_denial_bound_to_mutation_request_rejection=true" \
  "mutation_request_non_executable=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$MUTATION_REQUEST_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request source build guard: packet generation failed" >&2
    echo "cjgui semantic-comparison-admitted mutation request source build guard: log=$PACKET_LOG" >&2
    exit 7
  fi
  MUTATION_REQUEST_PACKET="$(grep -Eo 'semantic_comparison_admitted_mutation_request_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$MUTATION_REQUEST_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted mutation request source build guard: provided packet missing $MUTATION_REQUEST_PACKET" >&2
    exit 8
  fi
  echo "provided_mutation_request_packet_used=true" > "$PACKET_LOG"
fi
if [[ -z "$MUTATION_REQUEST_PACKET" || ! -f "$MUTATION_REQUEST_PACKET" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: missing mutation request packet" >&2
  exit 9
fi

if [[ -z "$CLASSIFIER_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/classifier" \
    CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_PACKET="$MUTATION_REQUEST_PACKET" \
    zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request source build guard: classifier failed" >&2
    echo "cjgui semantic-comparison-admitted mutation request source build guard: log=$CLASSIFIER_LOG" >&2
    exit 10
  fi
  CLASSIFIER_PACKET="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$CLASSIFIER_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted mutation request source build guard: provided classifier packet missing $CLASSIFIER_PACKET" >&2
    exit 11
  fi
  echo "provided_classifier_packet_used=true" > "$CLASSIFIER_LOG"
fi
if [[ -z "$CLASSIFIER_PACKET" || ! -f "$CLASSIFIER_PACKET" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: missing classifier packet" >&2
  exit 12
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true" \
  "renderer_state_mutation_request_shape_defined=true" \
  "decision_denial_bound_to_mutation_request_rejection=true" \
  "mutation_request_non_executable=true" \
  "renderer_state_mutation_request_rejected=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$MUTATION_REQUEST_PACKET" "$fact"
done
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier_passed=true" \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route=admitted_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_preflight" \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true" \
  "renderer_state_mutation_request_rejected=true" \
  "renderer_state_write=false"; do
  require_file_fact "$CLASSIFIER_PACKET" "$fact"
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: public or foreign declaration found in owner" >&2
  exit 13
fi
if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: public or foreign declaration diff found" >&2
  exit 14
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: forbidden native/render/capture token found in owner" >&2
  exit 15
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: protected path modified" >&2
  exit 16
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: cjpm unavailable" >&2
  exit 17
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request source build guard: runtime package build failed" >&2
  echo "cjgui semantic-comparison-admitted mutation request source build guard: log=$BUILD_LOG" >&2
  exit 18
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_source_build_guard_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "mutation_request_packet=$MUTATION_REQUEST_PACKET"
  echo "classifier_packet=$CLASSIFIER_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier_passed=true"
  echo "source_build_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  grep -E '^result_envelope_suite_packet_source=' "$MUTATION_REQUEST_PACKET" | tail -1
  grep -E '^current_shell_result_envelope_rerun_ready=' "$MUTATION_REQUEST_PACKET" | tail -1
  grep -E '^current_shell_result_envelope_rerun_failure_classification=' "$MUTATION_REQUEST_PACKET" | tail -1
  grep -E '^semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route=' "$CLASSIFIER_PACKET" | tail -1
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true"
  echo "renderer_state_mutation_request_shape_defined=true"
  echo "decision_denial_bound_to_mutation_request_rejection=true"
  echo "mutation_request_non_executable=true"
  echo "mutation_request_dry_run_only=true"
  echo "renderer_state_mutation_request_rejected=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui semantic-comparison-admitted mutation request source build guard: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_source_build_guard"
echo "cjgui semantic-comparison-admitted mutation request source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui semantic-comparison-admitted mutation request source build guard: runtime_package_build_passed=true"
