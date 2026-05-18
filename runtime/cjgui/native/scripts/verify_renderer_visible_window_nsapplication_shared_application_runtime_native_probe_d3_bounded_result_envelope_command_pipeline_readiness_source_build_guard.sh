#!/usr/bin/env zsh
#
# 维护注释：本脚本为 stage105 command-pipeline readiness envelope 提供
# source/build/probe guard。它验证 owner、packet、classifier 与 runtime
# package build，且禁止 protected path / public surface / production bridge 扩张。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage105-command-pipeline-source-build"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_classifier.sh"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SOURCE_BUILD_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-pipeline-readiness-source-build.packet"
COMMAND_PIPELINE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_PACKET:-}"
CLASSIFIER_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_CLASSIFIER_PACKET:-}"

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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: missing executable script $script" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: log=$OWNER_LOG" >&2
  exit 4
fi

required_owner_facts=(
  "d3_bounded_result_envelope_command_pipeline_readiness_owner_present=true"
  "write_decision_join_input=true"
  "visible_window_environment_envelope_required=true"
  "appkit_harness_separate_from_metal_device=true"
  "layer_device_binding_before_drawable_required=true"
  "metal_device_before_command_queue_required=true"
  "command_queue_before_command_buffer_required=true"
  "command_buffer_and_render_pass_before_encoder_required=true"
  "pipeline_state_and_vertex_buffer_before_draw_required=true"
  "production_write_admission_before_renderer_state_write_required=true"
  "renderer_state_write=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: missing owner fact $fact" >&2
    exit 5
  fi
done

if [[ -z "$COMMAND_PIPELINE_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: log=$PACKET_LOG" >&2
    exit 6
  fi
  COMMAND_PIPELINE_PACKET="$(grep -Eo 'command_pipeline_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$COMMAND_PIPELINE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: provided packet missing $COMMAND_PIPELINE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_command_pipeline_packet_used=true"
    echo "command_pipeline_packet_path=$COMMAND_PIPELINE_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$COMMAND_PIPELINE_PACKET" || ! -f "$COMMAND_PIPELINE_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: missing command pipeline packet" >&2
  exit 8
fi

if [[ -z "$CLASSIFIER_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/classifier" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_PACKET="$COMMAND_PIPELINE_PACKET" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: log=$CLASSIFIER_LOG" >&2
    exit 9
  fi
  CLASSIFIER_PACKET="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: provided classifier packet missing $CLASSIFIER_PACKET" >&2
    exit 10
  fi
  {
    echo "provided_classifier_packet_used=true"
    echo "classifier_packet_path=$CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
fi

required_packet_facts=(
  "d3_bounded_result_envelope_command_pipeline_readiness_packet_passed=true"
  "visible_window_appkit_harness_ready=true"
  "command_pipeline_host_independent_probes_ready=true"
  "command_pipeline_readiness_envelope_ready=true"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  if ! grep -F "$fact" "$COMMAND_PIPELINE_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: missing packet fact $fact" >&2
    exit 11
  fi
done

required_classifier_facts=(
  "d3_bounded_result_envelope_command_pipeline_readiness_classifier_passed=true"
  "visible_window_appkit_harness_ready=true"
  "command_pipeline_readiness_envelope_ready=true"
  "appkit_harness_failure_domain=false"
  "cjgui_harness_gap_detected=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: missing classifier fact $fact" >&2
    exit 12
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: public or foreign declaration found in owner" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: public or foreign declaration diff found" >&2
  exit 14
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: forbidden application/visible/render token found in owner" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: forbidden production native bridge diff found" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: log=$BUILD_LOG" >&2
  exit 19
fi

{
  echo "d3_bounded_result_envelope_command_pipeline_readiness_source_build_guard_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "command_pipeline_packet_log=$PACKET_LOG"
  echo "command_pipeline_packet=$COMMAND_PIPELINE_PACKET"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$CLASSIFIER_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_packet_passed=true"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_classifier_passed=true"
  echo "source_build_command_pipeline_readiness_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "visible_window_appkit_harness_ready=true"
  echo "command_pipeline_host_independent_probes_ready=true"
  echo "command_pipeline_readiness_envelope_ready=true"
  grep -E '^isolated_metal_device_available=' "$COMMAND_PIPELINE_PACKET" | tail -1
  grep -E '^host_metal_unavailable_classified=' "$COMMAND_PIPELINE_PACKET" | tail -1
  grep -E '^current_shell_command_pipeline_native_execution_ready=' "$COMMAND_PIPELINE_PACKET" | tail -1
  grep -E '^current_shell_failure_classification=' "$CLASSIFIER_PACKET" | tail -1
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$(grep -E '^runtime_native_probe_execution=' "$COMMAND_PIPELINE_PACKET" | tail -1 | cut -d= -f2-)"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SOURCE_BUILD_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: route_classification=d3_bounded_result_envelope_command_pipeline_readiness_source_build_guard"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: source_build_packet_path=$SOURCE_BUILD_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: command_pipeline_readiness_envelope_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness source build guard: renderer_state_write=false"
