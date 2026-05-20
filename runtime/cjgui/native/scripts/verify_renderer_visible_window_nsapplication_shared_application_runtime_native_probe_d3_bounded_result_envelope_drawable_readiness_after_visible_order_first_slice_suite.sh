#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage135 drawable readiness after visible-order smoke
# first-slice focused suite。它消费 stage134 visible-order suite packet，
# 再验证 drawable readiness gate 与 command pipeline contract 的相邻闭环。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE135_TMPDIR:-/tmp/cjgui-stage135-drawable-readiness-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

DRAWABLE_PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice"
COMMAND_PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice"
DRAWABLE_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice.cj"
COMMAND_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice.cj"
DRAWABLE_OWNER_SCRIPT="$SCRIPT_DIR/${DRAWABLE_PREFIX}_owner.sh"
DRAWABLE_PACKET_SCRIPT="$SCRIPT_DIR/${DRAWABLE_PREFIX}_packet.sh"
COMMAND_OWNER_SCRIPT="$SCRIPT_DIR/${COMMAND_PREFIX}_owner.sh"
COMMAND_PACKET_SCRIPT="$SCRIPT_DIR/${COMMAND_PREFIX}_packet.sh"
DRAWABLE_OWNER_LOG="$TMP_DIR/drawable-owner.log"
DRAWABLE_PACKET_LOG="$TMP_DIR/drawable-packet.log"
COMMAND_OWNER_LOG="$TMP_DIR/command-owner.log"
COMMAND_PACKET_LOG="$TMP_DIR/command-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage135-drawable-readiness-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$DRAWABLE_OWNER_LOG"
: > "$DRAWABLE_PACKET_LOG"
: > "$COMMAND_OWNER_LOG"
: > "$COMMAND_PACKET_LOG"
: > "$BUILD_LOG"
: > "$SUITE_PACKET"

cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

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
    echo "cjgui stage135 drawable readiness suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "$DRAWABLE_OWNER_SCRIPT" "$DRAWABLE_PACKET_SCRIPT" "$COMMAND_OWNER_SCRIPT" "$COMMAND_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage135 drawable readiness suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage135 drawable readiness suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$DRAWABLE_OWNER_SCRIPT" > "$DRAWABLE_OWNER_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness suite: drawable owner probe failed" >&2
  echo "cjgui stage135 drawable readiness suite: log=$DRAWABLE_OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "drawable_readiness_after_visible_order_owner_present=true" \
  "stage134_visible_order_smoke_input_required=true" \
  "drawable_readiness_reprobe_required=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$DRAWABLE_OWNER_LOG" "$fact"
done

if ! zsh "$DRAWABLE_PACKET_SCRIPT" > "$DRAWABLE_PACKET_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness suite: drawable packet failed" >&2
  echo "cjgui stage135 drawable readiness suite: log=$DRAWABLE_PACKET_LOG" >&2
  exit 7
fi
drawable_packet="$(grep -Eo 'drawable_readiness_packet_path=[^[:space:]]+' "$DRAWABLE_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$drawable_packet" || ! -f "$drawable_packet" ]]; then
  echo "cjgui stage135 drawable readiness suite: missing drawable packet" >&2
  exit 8
fi
for fact in \
  "stage135_drawable_readiness_after_visible_order_first_slice_packet_passed=true" \
  "stage134_visible_order_smoke_suite_consumed=true" \
  "visible_order_smoke_observed=true" \
  "metal_device_binding_reprobe_executed=true" \
  "command_pipeline_contract_route_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$drawable_packet" "$fact"
done

if ! zsh "$COMMAND_OWNER_SCRIPT" > "$COMMAND_OWNER_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness suite: command owner probe failed" >&2
  echo "cjgui stage135 drawable readiness suite: log=$COMMAND_OWNER_LOG" >&2
  exit 9
fi
for fact in \
  "command_pipeline_contract_after_drawable_readiness_owner_present=true" \
  "drawable_readiness_packet_required=true" \
  "command_queue_contract_required=true" \
  "render_pass_descriptor_contract_required=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$COMMAND_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE135_DRAWABLE_READINESS_PACKET="$drawable_packet" zsh "$COMMAND_PACKET_SCRIPT" > "$COMMAND_PACKET_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness suite: command packet failed" >&2
  echo "cjgui stage135 drawable readiness suite: log=$COMMAND_PACKET_LOG" >&2
  exit 10
fi
command_packet="$(grep -Eo 'command_pipeline_contract_packet_path=[^[:space:]]+' "$COMMAND_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$command_packet" || ! -f "$command_packet" ]]; then
  echo "cjgui stage135 drawable readiness suite: missing command packet" >&2
  exit 11
fi
for fact in \
  "stage135_command_pipeline_contract_after_drawable_readiness_first_slice_packet_passed=true" \
  "drawable_readiness_packet_consumed=true" \
  "command_queue_contract_probe_executed=true" \
  "render_pass_descriptor_contract_probe_executed=true" \
  "render_pass_descriptor_create_destroy_probe=passed" \
  "command_buffer_created=false" \
  "render_command_encoder_created=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$command_packet" "$fact"
done

for source_file in "$DRAWABLE_SRC" "$COMMAND_SRC"; do
  if [[ ! -f "$source_file" ]]; then
    echo "cjgui stage135 drawable readiness suite: missing source owner $source_file" >&2
    exit 12
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$source_file" >/dev/null 2>&1; then
    echo "cjgui stage135 drawable readiness suite: public or foreign declaration found in $source_file" >&2
    exit 13
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$source_file" \
    | grep -E 'sharedApplication|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage135 drawable readiness suite: forbidden native/render token found in $source_file" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage135 drawable readiness suite: protected production bridge/state path modified" >&2
  exit 15
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage135 drawable readiness suite: cjpm unavailable" >&2
  exit 16
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness suite: runtime package build failed" >&2
  echo "cjgui stage135 drawable readiness suite: log=$BUILD_LOG" >&2
  exit 17
fi

drawable_route="$(fact_value "$drawable_packet" "drawable_readiness_route_classification")"
command_route="$(fact_value "$command_packet" "command_pipeline_contract_route_classification")"
metal_binding_probe="$(fact_value "$drawable_packet" "metal_device_binding_probe")"
command_queue_probe="$(fact_value "$command_packet" "command_queue_create_destroy_probe")"
render_pass_probe="$(fact_value "$command_packet" "render_pass_descriptor_create_destroy_probe")"

{
  echo "stage135_drawable_readiness_after_visible_order_first_slice_suite_version=1"
  echo "drawable_owner_log=$DRAWABLE_OWNER_LOG"
  echo "drawable_packet_log=$DRAWABLE_PACKET_LOG"
  echo "drawable_readiness_packet=$drawable_packet"
  echo "command_owner_log=$COMMAND_OWNER_LOG"
  echo "command_packet_log=$COMMAND_PACKET_LOG"
  echo "command_pipeline_contract_packet=$command_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage135_drawable_readiness_owner_probe_passed=true"
  echo "stage135_drawable_readiness_packet_passed=true"
  echo "stage135_command_pipeline_contract_owner_probe_passed=true"
  echo "stage135_command_pipeline_contract_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage135_public_foreign_scan_passed=true"
  echo "stage135_forbidden_native_render_token_scan_passed=true"
  echo "stage135_protected_path_scan_passed=true"
  echo "drawable_readiness_route_classification=$drawable_route"
  echo "command_pipeline_contract_route_classification=$command_route"
  echo "metal_device_binding_probe=$metal_binding_probe"
  echo "command_queue_create_destroy_probe=$command_queue_probe"
  echo "render_pass_descriptor_create_destroy_probe=$render_pass_probe"
  grep -E '^next_drawable_called=' "$drawable_packet" | tail -1
  grep -E '^drawable_readiness_probe_executed=' "$drawable_packet" | tail -1
  grep -E '^drawable_acquired=' "$drawable_packet" | tail -1
  echo "command_buffer_created=false"
  echo "render_command_encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "next_route=production_next_command_buffer_render_encoder_contract_after_drawable_readiness"
  echo "stage135_drawable_readiness_after_visible_order_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage135 drawable readiness suite: route_classification=stage135_drawable_readiness_after_visible_order_first_slice_suite"
echo "cjgui stage135 drawable readiness suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage135 drawable readiness suite: drawable_route=$drawable_route"
echo "cjgui stage135 drawable readiness suite: command_route=$command_route"
echo "cjgui stage135 drawable readiness suite: renderer_state_write=false"
