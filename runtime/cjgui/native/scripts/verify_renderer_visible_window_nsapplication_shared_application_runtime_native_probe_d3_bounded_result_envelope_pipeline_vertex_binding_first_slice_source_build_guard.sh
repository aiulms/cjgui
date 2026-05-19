#!/usr/bin/env zsh
#
# 维护注释：本脚本为 stage112 pipeline / vertex binding first-slice envelope
# 提供 source/build/probe guard。它验证 owner、packet、classifier、runtime
# package build 与 protected/public/forbidden scans。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage112-pipeline-vertex-binding-first-slice-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_classifier.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-result-envelope-pipeline-vertex-binding-first-slice-source-build.packet"
READINESS_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_PIPELINE_VERTEX_BINDING_FIRST_SLICE_PACKET:-}"
CLASSIFIER_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_PIPELINE_VERTEX_BINDING_FIRST_SLICE_CLASSIFIER_PACKET:-}"

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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: log=$OWNER_LOG" >&2
  exit 6
fi

required_owner_facts=(
  "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_owner_present=true"
  "pipeline_vertex_preparation_first_slice_input=true"
  "positive_pipeline_vertex_preparation_envelope_before_binding_required=true"
  "bounded_isolated_pipeline_vertex_binding_probe_required=true"
  "probe_local_render_command_encoder_required=true"
  "probe_local_pipeline_state_binding_required=true"
  "probe_local_static_triangle_vertex_buffer_binding_required=true"
  "end_encoding_after_binding_before_cleanup_required=true"
  "draw_commit_present_gpu_render_blocked=true"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$READINESS_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: log=$PACKET_LOG" >&2
    exit 7
  fi
  READINESS_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$READINESS_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: provided packet missing $READINESS_PACKET" >&2
    exit 8
  fi
  {
    echo "provided_readiness_packet_used=true"
    echo "readiness_packet_path=$READINESS_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$READINESS_PACKET" || ! -f "$READINESS_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: missing readiness packet" >&2
  exit 9
fi

if [[ -z "$CLASSIFIER_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/classifier" \
    CJGUI_D3_BOUNDED_RESULT_ENVELOPE_PIPELINE_VERTEX_BINDING_FIRST_SLICE_PACKET="$READINESS_PACKET" \
    zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: log=$CLASSIFIER_LOG" >&2
    exit 10
  fi
  CLASSIFIER_PACKET="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: provided classifier packet missing $CLASSIFIER_PACKET" >&2
    exit 11
  fi
  {
    echo "provided_classifier_packet_used=true"
    echo "classifier_packet_path=$CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
fi

if [[ -z "$CLASSIFIER_PACKET" || ! -f "$CLASSIFIER_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: missing classifier packet" >&2
  exit 12
fi

required_packet_facts=(
  "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_packet_passed=true"
  "pipeline_vertex_preparation_first_slice_envelope_ready=true"
  "pipeline_vertex_binding_first_slice_owner_ready=true"
  "positive_pipeline_vertex_preparation_envelope_before_binding_required=true"
  "production_pipeline_vertex_binding=false"
  "draw_called=false"
  "commit_called=false"
  "present_called=false"
  "gpu_work_submitted=false"
  "render_executed=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$READINESS_PACKET" "$fact"
done

required_classifier_facts=(
  "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_classifier_passed=true"
  "production_pipeline_vertex_binding=false"
  "draw_called=false"
  "commit_called=false"
  "present_called=false"
  "gpu_work_submitted=false"
  "render_executed=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_classifier_facts[@]}"; do
  require_file_fact "$CLASSIFIER_PACKET" "$fact"
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: public or foreign declaration found in owner" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: public or foreign declaration diff found" >&2
  exit 14
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: forbidden application/visible/render token found in owner" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[+][[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: forbidden production native bridge diff found" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: log=$BUILD_LOG" >&2
  exit 19
fi

{
  echo "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_source_build_guard_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "readiness_packet_log=$PACKET_LOG"
  echo "readiness_packet=$READINESS_PACKET"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$CLASSIFIER_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_classifier_passed=true"
  echo "source_build_pipeline_vertex_binding_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  grep -E '^isolated_metal_device_available=' "$READINESS_PACKET" | tail -1
  grep -E '^stage111_current_shell_pipeline_vertex_preparation_first_slice_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^bounded_pipeline_vertex_binding_first_slice_should_execute=' "$READINESS_PACKET" | tail -1
  grep -E '^bounded_pipeline_vertex_binding_first_slice_executed=' "$READINESS_PACKET" | tail -1
  grep -E '^current_shell_pipeline_vertex_binding_first_slice_ready=' "$READINESS_PACKET" | tail -1
  grep -E '^pipeline_vertex_binding_first_slice_failure_classification=' "$READINESS_PACKET" | tail -1
  grep -E '^render_command_encoder_created=' "$READINESS_PACKET" | tail -1
  grep -E '^end_encoding_called=' "$READINESS_PACKET" | tail -1
  grep -E '^pipeline_state_created=' "$READINESS_PACKET" | tail -1
  grep -E '^vertex_buffer_created=' "$READINESS_PACKET" | tail -1
  grep -E '^pipeline_state_bound=' "$READINESS_PACKET" | tail -1
  grep -E '^vertex_buffer_bound=' "$READINESS_PACKET" | tail -1
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: route_classification=d3_bounded_result_envelope_pipeline_vertex_binding_first_slice_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 bounded pipeline vertex binding first slice source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
