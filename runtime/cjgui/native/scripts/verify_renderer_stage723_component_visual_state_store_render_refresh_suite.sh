#!/usr/bin/env zsh
#
# Focused suite for stage723. It consumes stage722 and verifies that dry-run
# state store deltas can refresh RenderCommand and host-inspection surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE723_TMPDIR:-/private/tmp/cjgui-stage721-stage724/stage723}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage723-component-visual-state-store-render-refresh-suite.packet"
STAGE722_SUITE_PACKET="${CJGUI_STAGE723_INPUT_PACKET:-${CJGUI_STAGE722_COMPONENT_VISUAL_STATE_STORE_DELTA_ROLLBACK_SUITE_PACKET:-/private/tmp/cjgui-stage721-stage724/stage722/stage722-component-visual-state-store-delta-rollback-suite.packet}}"
STAGE722_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage722_component_visual_state_store_delta_rollback_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage723_component_visual_state_store_render_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage723-component-visual-state-store-render-refresh-owner.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
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
    echo "cjgui stage723 component visual state store render refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE722_SUITE_PACKET" ]]; then
  zsh "$STAGE722_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage722_component_visual_state_store_delta_rollback_consumed=true" \
  "state_store_render_command_refresh_receipt_materialized=true" \
  "state_store_layout_style_text_focus_refresh_surface_materialized=true" \
  "state_store_host_inspection_preview_materialized=true" \
  "render_refresh_bound_to_rollback_snapshot=true" \
  "stage724_component_visual_state_store_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage722_component_visual_state_store_delta_rollback_suite_version=1" \
  "shared_visual_state_delta_ledger_materialized=true" \
  "visual_state_rollback_snapshot_materialized=true" \
  "stage723_component_visual_state_store_render_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE722_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage722_component_visual_state_store_delta_rollback.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage723_component_visual_state_store_render_refresh.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage723 component visual state store render refresh suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage723 component visual state store render refresh suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage723 component visual state store render refresh suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage723 component visual state store render refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage723 component visual state store render refresh suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage723 component visual state store render refresh suite: runtime package build failed" >&2
  echo "cjgui stage723 component visual state store render refresh suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage723_component_visual_state_store_render_refresh_suite_version=1"
  echo "stage722_component_visual_state_store_delta_rollback_suite_packet=$STAGE722_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage722_stage723_public_foreign_scan_passed=true"
  echo "stage722_stage723_forbidden_native_render_token_scan_passed=true"
  echo "stage723_protected_path_scan_passed=true"
  echo "next_route=stage724_component_visual_state_store_manager_after_stage723"
  echo "stage723_component_visual_state_store_render_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage723 component visual state store render refresh suite: route_classification=component_visual_state_store_render_refresh_ready"
echo "cjgui stage723 component visual state store render refresh suite: suite_packet_path=$SUITE_PACKET"
