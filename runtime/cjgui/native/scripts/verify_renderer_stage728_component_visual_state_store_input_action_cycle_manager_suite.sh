#!/usr/bin/env zsh
#
# Focused suite for stage728. It consumes stage727, verifies the shared
# input/action visual state store cycle manager, builds runtime/cjgui, and scans boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE728_TMPDIR:-/private/tmp/cjgui-stage725-stage728/stage728}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage728-component-visual-state-store-input-action-cycle-manager-suite.packet"
STAGE727_SUITE_PACKET="${CJGUI_STAGE728_INPUT_PACKET:-${CJGUI_STAGE727_COMPONENT_VISUAL_STATE_STORE_RENDER_RESULT_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage725-stage728/stage727/stage727-component-visual-state-store-render-result-host-surface-suite.packet}}"
STAGE727_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage727_component_visual_state_store_render_result_host_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage728_component_visual_state_store_input_action_cycle_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage728-component-visual-state-store-input-action-cycle-manager-owner.log"

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
    echo "cjgui stage728 component visual state store input action cycle manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE727_SUITE_PACKET" ]]; then
  zsh "$STAGE727_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage727_component_visual_state_store_render_result_host_surface_consumed=true" \
  "stage726_component_visual_state_store_action_reducer_preflight_consumed_transitively=true" \
  "stage725_component_visual_state_store_input_action_bridge_consumed_transitively=true" \
  "stage724_component_visual_state_store_manager_consumed_transitively=true" \
  "shared_visual_state_store_input_action_cycle_manager_materialized=true" \
  "visual_state_store_input_action_runtime_shape_materialized=true" \
  "visual_state_store_input_action_execution_receipt_contract_materialized=true" \
  "cycle_order_input_action_state_store_mutation_render_host_result_materialized=true" \
  "future_per_demo_input_action_state_store_template_need_reduced=true" \
  "stage729_component_visual_state_store_layout_style_focus_resolver_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage727_component_visual_state_store_render_result_host_surface_suite_version=1" \
  "visual_state_store_render_result_surface_materialized=true" \
  "visual_state_store_host_inspection_result_materialized=true" \
  "stage728_component_visual_state_store_input_action_cycle_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE727_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage725_component_visual_state_store_input_action_bridge.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage726_component_visual_state_store_action_reducer_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage727_component_visual_state_store_render_result_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage728_component_visual_state_store_input_action_cycle_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage728 component visual state store input action cycle manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage728 component visual state store input action cycle manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage728 component visual state store input action cycle manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage728 component visual state store input action cycle manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage728 component visual state store input action cycle manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage728 component visual state store input action cycle manager suite: runtime package build failed" >&2
  echo "cjgui stage728 component visual state store input action cycle manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage728_component_visual_state_store_input_action_cycle_manager_suite_version=1"
  echo "stage727_component_visual_state_store_render_result_host_surface_suite_packet=$STAGE727_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage725_stage728_public_foreign_scan_passed=true"
  echo "stage725_stage728_forbidden_native_render_token_scan_passed=true"
  echo "stage728_protected_path_scan_passed=true"
  echo "next_route=stage729_component_visual_state_store_layout_style_focus_resolver_after_stage728"
  echo "stage728_component_visual_state_store_input_action_cycle_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage728 component visual state store input action cycle manager suite: route_classification=component_visual_state_store_input_action_cycle_manager_ready"
echo "cjgui stage728 component visual state store input action cycle manager suite: suite_packet_path=$SUITE_PACKET"
