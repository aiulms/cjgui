#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage139 draw-call after stage138 pipeline / vertex
# binding contract focused suite。它消费 stage138 suite packet，并保持
# commit / present / state write 阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE139_TMPDIR:-/tmp/cjgui-stage139-draw-call-after-binding-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice"
OWNER_SCRIPT="$SCRIPT_DIR/${PREFIX}_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/${PREFIX}_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage139-draw-call-after-pipeline-vertex-binding-contract-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
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
    echo "cjgui stage139 draw call suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "$OWNER_SCRIPT" "$PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage139 draw call suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage139 draw call suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage139 draw call suite: owner probe failed" >&2
  echo "cjgui stage139 draw call suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage139_draw_call_after_pipeline_vertex_binding_contract_owner_present=true" \
  "stage138_pipeline_vertex_binding_packet_required=true" \
  "bounded_draw_call_probe_required=true" \
  "probe_local_draw_primitives_call_required=true" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage139 draw call suite: packet failed" >&2
  echo "cjgui stage139 draw call suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'draw_call_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage139 draw call suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_packet_passed=true" \
  "stage138_pipeline_vertex_binding_packet_consumed=true" \
  "positive_pipeline_vertex_binding_before_draw_required=true" \
  "commit_called=false" \
  "present_called=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "draw_call_route_classification")"
if [[ "$route" == "draw_call_after_pipeline_vertex_binding_contract_ready" ]]; then
  for fact in \
    "bounded_draw_call_executed=true" \
    "current_shell_draw_call_ready=true" \
    "pipeline_state_bound=true" \
    "vertex_buffer_bound=true" \
    "draw_called=true"; do
    require_file_fact "$packet" "$fact"
  done
elif [[ "$route" == "host_metal_device_unavailable" ]]; then
  for fact in \
    "bounded_draw_call_executed=false" \
    "current_shell_draw_call_ready=false" \
    "draw_called=false"; do
    require_file_fact "$packet" "$fact"
  done
elif [[ "$route" == "blocked_pending_pipeline_vertex_binding_contract" ]]; then
  require_file_fact "$packet" "bounded_draw_call_should_execute=false"
else
  echo "cjgui stage139 draw call suite: unexpected route $route" >&2
  exit 9
fi

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage139 draw call suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage139 draw call suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage139 draw call suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage139 draw call suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage139 draw call suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage139 draw call suite: runtime package build failed" >&2
  echo "cjgui stage139 draw call suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "draw_call_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage139_owner_probe_passed=true"
  echo "stage139_draw_call_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage139_public_foreign_scan_passed=true"
  echo "stage139_forbidden_native_render_token_scan_passed=true"
  echo "stage139_protected_path_scan_passed=true"
  echo "draw_call_route_classification=$route"
  grep -E '^stage138_pipeline_vertex_binding_route_classification=' "$packet" | tail -1
  grep -E '^pipeline_state_bound=' "$packet" | tail -1
  grep -E '^vertex_buffer_bound=' "$packet" | tail -1
  grep -E '^bounded_draw_call_should_execute=' "$packet" | tail -1
  grep -E '^bounded_draw_call_executed=' "$packet" | tail -1
  grep -E '^current_shell_draw_call_ready=' "$packet" | tail -1
  grep -E '^draw_called=' "$packet" | tail -1
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
  echo "next_route=production_next_command_buffer_commit_no_present_after_draw_call_contract"
  echo "stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage139 draw call suite: route_classification=stage139_draw_call_after_pipeline_vertex_binding_contract_first_slice_suite"
echo "cjgui stage139 draw call suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage139 draw call suite: draw_call_route=$route"
echo "cjgui stage139 draw call suite: renderer_state_write=false"
