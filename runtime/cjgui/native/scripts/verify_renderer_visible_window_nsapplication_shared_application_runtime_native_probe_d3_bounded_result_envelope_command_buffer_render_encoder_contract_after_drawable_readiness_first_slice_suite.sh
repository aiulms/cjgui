#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage136 command buffer / render encoder contract after
# drawable readiness focused suite。它消费 stage135 command pipeline packet，
# 验证 command buffer create/destroy、probe-local color attachment +
# render encoder/endEncoding，并保持 draw / commit / present / state write 阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE136_TMPDIR:-/tmp/cjgui-stage136-command-buffer-render-encoder-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice"
OWNER_SCRIPT="$SCRIPT_DIR/${PREFIX}_owner.sh"
COMMAND_BUFFER_PACKET_SCRIPT="$SCRIPT_DIR/${PREFIX}_command_buffer_packet.sh"
RENDER_ENCODER_PACKET_SCRIPT="$SCRIPT_DIR/${PREFIX}_render_encoder_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
COMMAND_BUFFER_PACKET_LOG="$TMP_DIR/command-buffer-packet.log"
RENDER_ENCODER_PACKET_LOG="$TMP_DIR/render-encoder-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage136-command-buffer-render-encoder-contract-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$COMMAND_BUFFER_PACKET_LOG"
: > "$RENDER_ENCODER_PACKET_LOG"
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
    echo "cjgui stage136 command buffer render encoder suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "$OWNER_SCRIPT" "$COMMAND_BUFFER_PACKET_SCRIPT" "$RENDER_ENCODER_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage136 command buffer render encoder suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage136 command buffer render encoder suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: owner probe failed" >&2
  echo "cjgui stage136 command buffer render encoder suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "command_buffer_render_encoder_contract_after_drawable_readiness_owner_present=true" \
  "stage135_command_pipeline_packet_required=true" \
  "command_buffer_create_destroy_contract_required=true" \
  "bounded_render_encoder_probe_required=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$COMMAND_BUFFER_PACKET_SCRIPT" > "$COMMAND_BUFFER_PACKET_LOG" 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: command buffer packet failed" >&2
  echo "cjgui stage136 command buffer render encoder suite: log=$COMMAND_BUFFER_PACKET_LOG" >&2
  exit 7
fi
command_buffer_packet="$(grep -Eo 'command_buffer_contract_packet_path=[^[:space:]]+' "$COMMAND_BUFFER_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$command_buffer_packet" || ! -f "$command_buffer_packet" ]]; then
  echo "cjgui stage136 command buffer render encoder suite: missing command buffer packet" >&2
  exit 8
fi
for fact in \
  "stage136_command_buffer_contract_after_drawable_readiness_first_slice_packet_passed=true" \
  "stage135_command_pipeline_contract_packet_consumed=true" \
  "bounded_command_buffer_probe_executed=true" \
  "render_command_encoder_created=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$command_buffer_packet" "$fact"
done
command_buffer_route="$(fact_value "$command_buffer_packet" "command_buffer_contract_route_classification")"
if [[ "$command_buffer_route" == "command_buffer_create_destroy_contract_ready" ]]; then
  require_file_fact "$command_buffer_packet" "command_buffer_create_destroy_probe=passed"
  require_file_fact "$command_buffer_packet" "command_buffer_created=true"
  require_file_fact "$command_buffer_packet" "command_buffer_destroyed=true"
elif [[ "$command_buffer_route" == "host_metal_device_unavailable" ]]; then
  require_file_fact "$command_buffer_packet" "command_buffer_create_destroy_probe=skipped_no_device"
  require_file_fact "$command_buffer_packet" "command_buffer_created=false"
  require_file_fact "$command_buffer_packet" "command_buffer_destroyed=false"
else
  echo "cjgui stage136 command buffer render encoder suite: unexpected command buffer route $command_buffer_route" >&2
  exit 17
fi

if ! env CJGUI_STAGE136_COMMAND_BUFFER_CONTRACT_PACKET="$command_buffer_packet" \
  zsh "$RENDER_ENCODER_PACKET_SCRIPT" > "$RENDER_ENCODER_PACKET_LOG" 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: render encoder packet failed" >&2
  echo "cjgui stage136 command buffer render encoder suite: log=$RENDER_ENCODER_PACKET_LOG" >&2
  exit 9
fi
render_encoder_packet="$(grep -Eo 'render_encoder_contract_packet_path=[^[:space:]]+' "$RENDER_ENCODER_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$render_encoder_packet" || ! -f "$render_encoder_packet" ]]; then
  echo "cjgui stage136 command buffer render encoder suite: missing render encoder packet" >&2
  exit 10
fi
for fact in \
  "stage136_render_encoder_contract_after_command_buffer_first_slice_packet_passed=true" \
  "command_buffer_contract_packet_consumed=true" \
  "pipeline_state_bound=false" \
  "vertex_buffer_bound=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$render_encoder_packet" "$fact"
done
render_encoder_route="$(fact_value "$render_encoder_packet" "render_encoder_contract_route_classification")"
if [[ "$render_encoder_route" == "bounded_command_buffer_render_pass_encoder_contract_ready" ]]; then
  for fact in \
    "bounded_render_encoder_probe_executed=true" \
    "current_shell_render_encoder_contract_ready=true" \
    "next_drawable_called=true" \
    "drawable_acquired=true" \
    "drawable_texture_observed=true" \
    "command_queue_created=true" \
    "command_buffer_created=true" \
    "render_pass_descriptor_created=true" \
    "color_attachment_configured=true" \
    "render_command_encoder_created=true" \
    "end_encoding_called=true"; do
    require_file_fact "$render_encoder_packet" "$fact"
  done
elif [[ "$render_encoder_route" == "host_metal_device_unavailable" ]]; then
  for fact in \
    "bounded_render_encoder_probe_executed=false" \
    "current_shell_render_encoder_contract_ready=false" \
    "next_drawable_called=false" \
    "drawable_acquired=false" \
    "render_command_encoder_created=false" \
    "end_encoding_called=false"; do
    require_file_fact "$render_encoder_packet" "$fact"
  done
else
  echo "cjgui stage136 command buffer render encoder suite: unexpected render encoder route $render_encoder_route" >&2
  exit 18
fi

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage136 command buffer render encoder suite: missing source owner $OWNER_SRC" >&2
  exit 11
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: public or foreign declaration found" >&2
  exit 12
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: forbidden native/render token found in owner" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage136 command buffer render encoder suite: runtime package build failed" >&2
  echo "cjgui stage136 command buffer render encoder suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage136_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "command_buffer_packet_log=$COMMAND_BUFFER_PACKET_LOG"
  echo "command_buffer_contract_packet=$command_buffer_packet"
  echo "render_encoder_packet_log=$RENDER_ENCODER_PACKET_LOG"
  echo "render_encoder_contract_packet=$render_encoder_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage136_owner_probe_passed=true"
  echo "stage136_command_buffer_contract_packet_passed=true"
  echo "stage136_render_encoder_contract_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage136_public_foreign_scan_passed=true"
  echo "stage136_forbidden_native_render_token_scan_passed=true"
  echo "stage136_protected_path_scan_passed=true"
  echo "command_buffer_contract_route_classification=$command_buffer_route"
  echo "render_encoder_contract_route_classification=$render_encoder_route"
  grep -E '^bounded_command_buffer_probe_executed=' "$command_buffer_packet" | tail -1
  grep -E '^command_buffer_create_destroy_probe=' "$command_buffer_packet" | tail -1
  grep -E '^bounded_render_encoder_probe_executed=' "$render_encoder_packet" | tail -1
  grep -E '^next_drawable_called=' "$render_encoder_packet" | tail -1
  grep -E '^drawable_acquired=' "$render_encoder_packet" | tail -1
  grep -E '^drawable_texture_observed=' "$render_encoder_packet" | tail -1
  grep -E '^command_queue_created=' "$render_encoder_packet" | tail -1
  grep -E '^command_buffer_created=' "$render_encoder_packet" | tail -1
  grep -E '^render_pass_descriptor_created=' "$render_encoder_packet" | tail -1
  grep -E '^color_attachment_configured=' "$render_encoder_packet" | tail -1
  grep -E '^render_command_encoder_created=' "$render_encoder_packet" | tail -1
  grep -E '^end_encoding_called=' "$render_encoder_packet" | tail -1
  echo "pipeline_state_bound=false"
  echo "vertex_buffer_bound=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "first_frame_observed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=production_next_pipeline_vertex_binding_contract_after_render_encoder"
  echo "stage136_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage136 command buffer render encoder suite: route_classification=stage136_command_buffer_render_encoder_contract_after_drawable_readiness_first_slice_suite"
echo "cjgui stage136 command buffer render encoder suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage136 command buffer render encoder suite: command_buffer_route=$command_buffer_route"
echo "cjgui stage136 command buffer render encoder suite: render_encoder_route=$render_encoder_route"
echo "cjgui stage136 command buffer render encoder suite: renderer_state_write=false"
