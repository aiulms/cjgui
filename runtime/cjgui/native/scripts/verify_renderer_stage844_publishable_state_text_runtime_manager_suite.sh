#!/usr/bin/env zsh
#
# Focused suite for stage844. It consumes stage843, builds runtime/cjgui, and
# records the shared publishable text runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE844_TMPDIR:-/private/tmp/cjgui-stage841-stage844/stage844}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage844-publishable-state-text-runtime-manager-suite.packet"
STAGE843_SUITE_PACKET="${CJGUI_STAGE844_INPUT_PACKET:-${CJGUI_STAGE843_PUBLISHABLE_STATE_TEXT_DEMO_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage841-stage844/stage843/stage843-publishable-state-text-demo-surface-suite.packet}}"
STAGE843_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage843_publishable_state_text_demo_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage844_publishable_state_text_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage844-publishable-state-text-runtime-manager-owner.log"

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
    echo "cjgui stage844 publishable state text runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE843_SUITE_PACKET" ]] || ! grep -F "stage843_publishable_state_text_demo_surface_suite_passed=true" "$STAGE843_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE843_TMPDIR="$TMP_DIR/stage843" zsh "$STAGE843_SUITE_SCRIPT" >/dev/null
  STAGE843_SUITE_PACKET="$TMP_DIR/stage843/stage843-publishable-state-text-demo-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage843_publishable_state_text_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage843_publishable_state_text_demo_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage844_publishable_state_text_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage844_publishable_state_text_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage843_publishable_state_text_demo_surface_consumed=true" \
  "stage842_publishable_state_text_edit_preview_consumed_transitively=true" \
  "stage841_publishable_state_text_model_consumed_transitively=true" \
  "stage840_publishable_state_focus_runtime_manager_consumed_transitively=true" \
  "shared_publishable_text_runtime_manager_materialized=true" \
  "publishable_text_runtime_contract_materialized=true" \
  "publishable_text_execution_receipt_contract_materialized=true" \
  "cycle_order_publishable_state_text_demo_runtime_materialized=true" \
  "todo_text_runtime_surface_materialized=true" \
  "settings_text_runtime_surface_materialized=true" \
  "ai_generated_settings_text_runtime_surface_materialized=true" \
  "chat_composer_text_runtime_surface_materialized=true" \
  "file_browser_text_runtime_surface_materialized=true" \
  "text_runtime_manager_bound_to_stage841_text_model=true" \
  "text_runtime_manager_bound_to_stage842_edit_preview=true" \
  "text_runtime_manager_bound_to_stage843_demo_surface=true" \
  "future_per_demo_text_template_need_reduced=true" \
  "stage845_publishable_state_text_input_adapter_after_stage844_prepared=true" \
  "text_shaping_enabled=false" \
  "text_mutation=false" \
  "input_pipeline_execution=false" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage843_publishable_state_text_demo_surface_suite_passed=true" \
  "file_browser_text_inspection_surface_materialized=true" \
  "text_result_surface_receipt_materialized=true" \
  "stage844_publishable_state_text_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE843_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage841_publishable_state_text_model.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage842_publishable_state_text_edit_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage843_publishable_state_text_demo_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage844_publishable_state_text_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage844 publishable state text runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage844 publishable state text runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage844 publishable state text runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(41|42|43|44)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage844 publishable state text runtime manager suite: unexpected stage841-844 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage844 publishable state text runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage844 publishable state text runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage844 publishable state text runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage844 publishable state text runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage844_publishable_state_text_runtime_manager_suite_version=1"
  echo "stage843_suite_packet=$STAGE843_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage841_stage844_public_declaration_scan_passed=true"
  echo "stage841_stage844_forbidden_native_render_token_scan_passed=true"
  echo "stage844_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage845_publishable_state_text_input_adapter_after_stage844"
  echo "stage844_publishable_state_text_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage844 publishable state text runtime manager suite: route_classification=text_runtime_manager"
echo "cjgui stage844 publishable state text runtime manager suite: suite_packet_path=$SUITE_PACKET"
