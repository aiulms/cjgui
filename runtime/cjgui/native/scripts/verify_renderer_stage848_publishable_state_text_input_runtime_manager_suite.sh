#!/usr/bin/env zsh
#
# Focused suite for stage848. It consumes stage847, builds runtime/cjgui, and
# records the shared publishable text input runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE848_TMPDIR:-/private/tmp/cjgui-stage845-stage848/stage848}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage848-publishable-state-text-input-runtime-manager-suite.packet"
STAGE847_SUITE_PACKET="${CJGUI_STAGE848_INPUT_PACKET:-${CJGUI_STAGE847_PUBLISHABLE_STATE_TEXT_INPUT_DEMO_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage845-stage848/stage847/stage847-publishable-state-text-input-demo-surface-suite.packet}}"
STAGE847_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage847_publishable_state_text_input_demo_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage848_publishable_state_text_input_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage848-publishable-state-text-input-runtime-manager-owner.log"

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
    echo "cjgui stage848 publishable state text input runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE847_SUITE_PACKET" ]] || ! grep -F "stage847_publishable_state_text_input_demo_surface_suite_passed=true" "$STAGE847_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE847_TMPDIR="$TMP_DIR/stage847" zsh "$STAGE847_SUITE_SCRIPT" >/dev/null
  STAGE847_SUITE_PACKET="$TMP_DIR/stage847/stage847-publishable-state-text-input-demo-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage847_publishable_state_text_input_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage847_publishable_state_text_input_demo_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage848_publishable_state_text_input_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage848_publishable_state_text_input_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage847_publishable_state_text_input_demo_surface_consumed=true" \
  "stage846_publishable_state_text_input_composition_preview_consumed_transitively=true" \
  "stage845_publishable_state_text_input_adapter_consumed_transitively=true" \
  "stage844_publishable_state_text_runtime_manager_consumed_transitively=true" \
  "shared_publishable_text_input_runtime_manager_materialized=true" \
  "publishable_text_input_runtime_contract_materialized=true" \
  "publishable_text_input_execution_receipt_contract_materialized=true" \
  "cycle_order_publishable_state_text_input_runtime_materialized=true" \
  "todo_text_input_runtime_surface_materialized=true" \
  "settings_text_input_runtime_surface_materialized=true" \
  "ai_generated_settings_text_input_runtime_surface_materialized=true" \
  "chat_composer_text_input_runtime_surface_materialized=true" \
  "file_browser_text_input_runtime_surface_materialized=true" \
  "text_input_runtime_bound_to_stage844_text_runtime_manager=true" \
  "text_input_runtime_bound_to_stage845_input_adapter=true" \
  "text_input_runtime_bound_to_stage846_composition_preview=true" \
  "text_input_runtime_bound_to_stage847_demo_surface=true" \
  "future_per_demo_text_input_template_need_reduced=true" \
  "stage849_publishable_state_text_input_state_update_render_bridge_prepared=true" \
  "text_input_pipeline_execution=false" \
  "state_update_committed=false" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage847_publishable_state_text_input_demo_surface_suite_passed=true" \
  "file_browser_text_input_preview_surface_materialized=true" \
  "text_input_result_surface_receipt_materialized=true" \
  "stage848_publishable_state_text_input_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE847_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage845_publishable_state_text_input_adapter.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage846_publishable_state_text_input_composition_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage847_publishable_state_text_input_demo_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage848_publishable_state_text_input_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage848 publishable state text input runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage848 publishable state text input runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage848 publishable state text input runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(45|46|47|48)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage848 publishable state text input runtime manager suite: unexpected stage845-848 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage848 publishable state text input runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage848 publishable state text input runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage848 publishable state text input runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage848 publishable state text input runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage848_publishable_state_text_input_runtime_manager_suite_version=1"
  echo "stage847_suite_packet=$STAGE847_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage845_stage848_public_declaration_scan_passed=true"
  echo "stage845_stage848_forbidden_native_render_token_scan_passed=true"
  echo "stage848_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage849_publishable_state_text_input_state_update_render_bridge_after_stage848"
  echo "stage848_publishable_state_text_input_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage848 publishable state text input runtime manager suite: route_classification=text_input_runtime_manager"
echo "cjgui stage848 publishable state text input runtime manager suite: suite_packet_path=$SUITE_PACKET"
