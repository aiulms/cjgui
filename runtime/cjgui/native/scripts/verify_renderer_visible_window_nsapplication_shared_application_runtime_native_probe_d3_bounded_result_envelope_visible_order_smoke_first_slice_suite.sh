#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage134 visible-order smoke first-slice focused suite。
# 它要求 owner、packet 与 bounded AppKit visible-order smoke probe 都存在并通过，
# 再跑 runtime build 与 public/protected/forbidden scans。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE134_TMPDIR:-/tmp/cjgui-stage134-visible-order-smoke-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

SCRIPT_PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice"
SRC_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice.cj"
OWNER_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_packet.sh"
PROBE_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_probe.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage134-visible-order-smoke-first-slice-suite.packet"

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
    echo "cjgui stage134 visible order smoke suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "$OWNER_SCRIPT" "$PACKET_SCRIPT" "$PROBE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage134 visible order smoke suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage134 visible order smoke suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage134 visible order smoke suite: owner probe failed" >&2
  echo "cjgui stage134 visible order smoke suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "runtime_owner_present=true" \
  "bounded_visible_order_smoke_probe_required=true" \
  "drawable_readiness_reprobe_route_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage134 visible order smoke suite: packet failed" >&2
  echo "cjgui stage134 visible order smoke suite: log=$PACKET_LOG" >&2
  exit 7
fi

visible_order_packet="$(grep -Eo 'visible_order_smoke_first_slice_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$visible_order_packet" || ! -f "$visible_order_packet" ]]; then
  echo "cjgui stage134 visible order smoke suite: missing visible-order packet" >&2
  exit 8
fi

for fact in \
  "stage134_visible_order_smoke_first_slice_packet_passed=true" \
  "bounded_visible_order_smoke_probe_executed=true" \
  "nsapplication_shared_application_observed=true" \
  "nswindow_created=true" \
  "nsview_content_view_attached=true" \
  "visible_order_smoke_called=true" \
  "visible_order_auto_close_cleanup_observed=true" \
  "metal_device_required=false" \
  "metal_device_binding_reprobe_executed=true" \
  "drawable_requested=false" \
  "first_frame_observed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$visible_order_packet" "$fact"
done

if [[ ! -f "$SRC_FILE" ]]; then
  echo "cjgui stage134 visible order smoke suite: missing source owner $SRC_FILE" >&2
  exit 9
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$SRC_FILE" >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke suite: public or foreign declaration found" >&2
  exit 10
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$SRC_FILE" \
  | grep -E 'sharedApplication|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|presentDrawable|commit\]|screencapture|CGWindow|CGDisplay|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke suite: forbidden native/render token found in source owner" >&2
  exit 11
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke suite: protected production bridge/state path modified" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke suite: cjpm unavailable" >&2
  exit 13
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage134 visible order smoke suite: runtime package build failed" >&2
  echo "cjgui stage134 visible order smoke suite: log=$BUILD_LOG" >&2
  exit 14
fi

route_classification="$(fact_value "$visible_order_packet" "visible_order_smoke_route_classification")"
visible_order_observed="$(fact_value "$visible_order_packet" "visible_order_smoke_observed")"
auto_close_observed="$(fact_value "$visible_order_packet" "visible_order_auto_close_cleanup_observed")"
metal_default_device_available="$(fact_value "$visible_order_packet" "metal_default_device_available")"
metal_device_binding_probe="$(fact_value "$visible_order_packet" "metal_device_binding_probe")"
visible_order_to_metal_next_gap="$(fact_value "$visible_order_packet" "visible_order_to_metal_next_gap")"

{
  echo "stage134_visible_order_smoke_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "visible_order_smoke_packet=$visible_order_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage134_visible_order_smoke_owner_probe_passed=true"
  echo "stage134_visible_order_smoke_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage134_public_foreign_scan_passed=true"
  echo "stage134_forbidden_native_render_token_scan_passed=true"
  echo "stage134_protected_path_scan_passed=true"
  echo "bounded_visible_order_smoke_probe_executed=true"
  echo "visible_order_smoke_route_classification=$route_classification"
  echo "visible_order_smoke_observed=$visible_order_observed"
  echo "visible_order_auto_close_cleanup_observed=$auto_close_observed"
  echo "nsapplication_window_view_chain_observed=true"
  echo "metal_device_required=false"
  echo "metal_device_binding_reprobe_executed=true"
  echo "metal_default_device_available=$metal_default_device_available"
  echo "metal_device_binding_probe=$metal_device_binding_probe"
  echo "visible_order_to_metal_next_gap=$visible_order_to_metal_next_gap"
  echo "drawable_requested=false"
  echo "first_frame_observed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "next_route=production_next_drawable_readiness_reprobe_after_visible_order_smoke"
  echo "stage134_visible_order_smoke_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage134 visible order smoke suite: route_classification=stage134_visible_order_smoke_first_slice_suite"
echo "cjgui stage134 visible order smoke suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage134 visible order smoke suite: visible_order_smoke_observed=$visible_order_observed"
echo "cjgui stage134 visible order smoke suite: renderer_state_write=false"
