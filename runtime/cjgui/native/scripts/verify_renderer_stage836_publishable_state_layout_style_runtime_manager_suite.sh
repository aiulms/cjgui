#!/usr/bin/env zsh
#
# Focused suite for stage836. It consumes stage835, builds runtime/cjgui, and
# records the shared layout/style runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE836_TMPDIR:-/private/tmp/cjgui-stage833-stage836/stage836}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage836-publishable-state-layout-style-runtime-manager-suite.packet"
STAGE835_SUITE_PACKET="${CJGUI_STAGE836_INPUT_PACKET:-${CJGUI_STAGE835_PUBLISHABLE_STATE_LAYOUT_STYLE_DEMO_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage833-stage836/stage835/stage835-publishable-state-layout-style-demo-surface-suite.packet}}"
STAGE835_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage835_publishable_state_layout_style_demo_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage836_publishable_state_layout_style_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage836-publishable-state-layout-style-runtime-manager-owner.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$BUILD_LOG"
: > "$PUBLIC_SCAN_LOG"
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
    echo "cjgui stage836 publishable state layout style runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE835_SUITE_PACKET" ]] || ! grep -F "stage835_publishable_state_layout_style_demo_surface_suite_passed=true" "$STAGE835_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE835_TMPDIR="$TMP_DIR/stage835" zsh "$STAGE835_SUITE_SCRIPT" >/dev/null
  STAGE835_SUITE_PACKET="$TMP_DIR/stage835/stage835-publishable-state-layout-style-demo-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage835_publishable_state_layout_style_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage835_publishable_state_layout_style_demo_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage836_publishable_state_layout_style_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage836_publishable_state_layout_style_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage835_publishable_state_layout_style_demo_surface_consumed=true" \
  "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true" \
  "stage833_publishable_state_layout_style_resolver_consumed_transitively=true" \
  "stage832_component_state_store_publishable_runtime_manager_consumed_transitively=true" \
  "shared_publishable_layout_style_runtime_manager_materialized=true" \
  "publishable_layout_style_runtime_contract_materialized=true" \
  "publishable_layout_style_execution_receipt_contract_materialized=true" \
  "cycle_order_publishable_state_layout_style_demo_runtime_materialized=true" \
  "todo_layout_style_runtime_surface_materialized=true" \
  "settings_layout_style_runtime_surface_materialized=true" \
  "ai_generated_settings_layout_style_runtime_surface_materialized=true" \
  "chat_composer_layout_style_runtime_surface_materialized=true" \
  "file_browser_layout_style_runtime_surface_materialized=true" \
  "layout_style_runtime_manager_bound_to_stage833_resolver=true" \
  "layout_style_runtime_manager_bound_to_stage834_measurement_plan=true" \
  "layout_style_runtime_manager_bound_to_stage835_demo_surface=true" \
  "future_per_demo_layout_style_template_need_reduced=true" \
  "stage837_publishable_state_focus_manager_after_stage836_prepared=true" \
  "layout_engine_enabled=false" \
  "style_resolver_production_enabled=false" \
  "text_shaping_enabled=false" \
  "focus_manager_enabled=false" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage835_publishable_state_layout_style_demo_surface_suite_passed=true" \
  "file_browser_layout_style_preview_surface_materialized=true" \
  "layout_style_result_surface_receipt_materialized=true" \
  "stage836_publishable_state_layout_style_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE835_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage833_publishable_state_layout_style_resolver.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage834_publishable_state_text_focus_measurement_plan.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage835_publishable_state_layout_style_demo_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage836_publishable_state_layout_style_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage836 publishable state layout style runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage836 publishable state layout style runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage836 publishable state layout style runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(33|34|35|36)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage836 publishable state layout style runtime manager suite: unexpected stage833-836 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage836 publishable state layout style runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage836 publishable state layout style runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage836 publishable state layout style runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage836 publishable state layout style runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage836_publishable_state_layout_style_runtime_manager_suite_version=1"
  echo "stage835_suite_packet=$STAGE835_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage833_stage836_public_declaration_scan_passed=true"
  echo "stage833_stage836_forbidden_native_render_token_scan_passed=true"
  echo "stage836_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage837_publishable_state_focus_manager_after_stage836"
  echo "stage836_publishable_state_layout_style_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage836 publishable state layout style runtime manager suite: route_classification=layout_style_runtime_manager"
echo "cjgui stage836 publishable state layout style runtime manager suite: suite_packet_path=$SUITE_PACKET"
