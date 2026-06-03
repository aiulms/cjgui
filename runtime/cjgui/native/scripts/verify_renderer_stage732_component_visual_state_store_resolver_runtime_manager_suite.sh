#!/usr/bin/env zsh
#
# Focused suite for stage732. It consumes stage731, verifies the shared
# resolver runtime manager, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE732_TMPDIR:-/private/tmp/cjgui-stage729-stage732/stage732}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage732-component-visual-state-store-resolver-runtime-manager-suite.packet"
STAGE731_SUITE_PACKET="${CJGUI_STAGE732_INPUT_PACKET:-${CJGUI_STAGE731_COMPONENT_VISUAL_STATE_STORE_RESOLVER_HOST_INSPECTION_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage729-stage732/stage731/stage731-component-visual-state-store-resolver-host-inspection-surface-suite.packet}}"
STAGE731_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage731_component_visual_state_store_resolver_host_inspection_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage732_component_visual_state_store_resolver_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage732-component-visual-state-store-resolver-runtime-manager-owner.log"

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
    echo "cjgui stage732 component visual state store resolver runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE731_SUITE_PACKET" ]]; then
  zsh "$STAGE731_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage731_component_visual_state_store_resolver_host_inspection_surface_consumed=true" \
  "stage730_component_visual_state_store_text_selection_projection_consumed_transitively=true" \
  "stage729_component_visual_state_store_layout_style_focus_resolver_consumed_transitively=true" \
  "stage728_component_visual_state_store_input_action_cycle_manager_consumed_transitively=true" \
  "shared_visual_state_store_resolver_runtime_manager_materialized=true" \
  "visual_state_store_resolver_runtime_contract_materialized=true" \
  "visual_state_store_resolver_execution_receipt_contract_materialized=true" \
  "cycle_order_state_store_resolve_text_host_result_runtime_materialized=true" \
  "future_per_demo_resolver_template_need_reduced=true" \
  "stage733_component_visual_state_store_commit_preflight_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage731_component_visual_state_store_resolver_host_inspection_surface_suite_version=1" \
  "visual_state_store_resolver_host_inspection_surface_materialized=true" \
  "visual_state_store_resolver_result_surface_refresh_materialized=true" \
  "stage732_component_visual_state_store_resolver_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE731_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage729_component_visual_state_store_layout_style_focus_resolver.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage730_component_visual_state_store_text_selection_projection.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage731_component_visual_state_store_resolver_host_inspection_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage732_component_visual_state_store_resolver_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage732 component visual state store resolver runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage732 component visual state store resolver runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage732 component visual state store resolver runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage732 component visual state store resolver runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage732 component visual state store resolver runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage732 component visual state store resolver runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage732 component visual state store resolver runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage732_component_visual_state_store_resolver_runtime_manager_suite_version=1"
  echo "stage731_component_visual_state_store_resolver_host_inspection_surface_suite_packet=$STAGE731_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage729_stage732_public_foreign_scan_passed=true"
  echo "stage729_stage732_forbidden_native_render_token_scan_passed=true"
  echo "stage732_protected_path_scan_passed=true"
  echo "next_route=stage733_component_visual_state_store_commit_preflight_after_stage732"
  echo "stage732_component_visual_state_store_resolver_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage732 component visual state store resolver runtime manager suite: route_classification=component_visual_state_store_resolver_runtime_manager_ready"
echo "cjgui stage732 component visual state store resolver runtime manager suite: suite_packet_path=$SUITE_PACKET"
