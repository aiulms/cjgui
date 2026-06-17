#!/usr/bin/env zsh
#
# Focused suite for stage851. It consumes stage850 and records five demo
# result/inspection surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE851_TMPDIR:-/private/tmp/cjgui-stage849-stage852/stage851}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage851-publishable-state-text-input-demo-result-surface-suite.packet"
STAGE850_SUITE_PACKET="${CJGUI_STAGE851_INPUT_PACKET:-${CJGUI_STAGE850_PUBLISHABLE_STATE_TEXT_INPUT_RENDER_COMMAND_REFRESH_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage849-stage852/stage850/stage850-publishable-state-text-input-render-command-refresh-preview-suite.packet}}"
STAGE850_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage850_publishable_state_text_input_render_command_refresh_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage851_publishable_state_text_input_demo_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage851-publishable-state-text-input-demo-result-surface-owner.log"

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
    echo "cjgui stage851 publishable state text input demo result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE850_SUITE_PACKET" ]] || ! grep -F "stage850_publishable_state_text_input_render_command_refresh_preview_suite_passed=true" "$STAGE850_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE850_TMPDIR="$TMP_DIR/stage850" zsh "$STAGE850_SUITE_SCRIPT" >/dev/null
  STAGE850_SUITE_PACKET="$TMP_DIR/stage850/stage850-publishable-state-text-input-render-command-refresh-preview-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage849_publishable_state_text_input_state_update_render_bridge_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage849_publishable_state_text_input_state_update_render_bridge_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage850_publishable_state_text_input_render_command_refresh_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage850_publishable_state_text_input_render_command_refresh_preview_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage851_publishable_state_text_input_demo_result_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage851_publishable_state_text_input_demo_result_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage850_publishable_state_text_input_render_command_refresh_preview_consumed=true" \
  "stage849_publishable_state_text_input_state_update_render_bridge_consumed_transitively=true" \
  "todo_text_input_state_render_result_surface_materialized=true" \
  "settings_text_input_state_render_result_surface_materialized=true" \
  "ai_generated_settings_text_input_state_render_result_surface_materialized=true" \
  "chat_composer_text_input_state_render_result_surface_materialized=true" \
  "file_browser_text_input_state_render_result_surface_materialized=true" \
  "text_input_state_render_host_inspection_rows_materialized=true" \
  "text_input_state_render_semantic_diff_receipt_materialized=true" \
  "stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_prepared=true" \
  "host_mutation=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage850_publishable_state_text_input_render_command_refresh_preview_suite_passed=true" \
  "text_value_render_command_refresh_preview_materialized=true" \
  "text_input_result_refresh_receipt_materialized=true" \
  "stage851_publishable_state_text_input_demo_result_surface_prepared=true"; do
  require_file_fact "$STAGE850_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage849_publishable_state_text_input_state_update_render_bridge.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage850_publishable_state_text_input_render_command_refresh_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage851_publishable_state_text_input_demo_result_surface.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage851 publishable state text input demo result surface suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage851 publishable state text input demo result surface suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage851 publishable state text input demo result surface suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(49|50|51)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage851 publishable state text input demo result surface suite: unexpected stage849-851 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage851 publishable state text input demo result surface suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage851 publishable state text input demo result surface suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage851 publishable state text input demo result surface suite: runtime package build failed" >&2
  echo "cjgui stage851 publishable state text input demo result surface suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage851_publishable_state_text_input_demo_result_surface_suite_version=1"
  echo "stage850_suite_packet=$STAGE850_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage849_stage851_public_declaration_scan_passed=true"
  echo "stage849_stage851_forbidden_native_render_token_scan_passed=true"
  echo "stage851_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_after_stage851"
  echo "stage851_publishable_state_text_input_demo_result_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage851 publishable state text input demo result surface suite: route_classification=text_input_demo_result_surface"
echo "cjgui stage851 publishable state text input demo result surface suite: suite_packet_path=$SUITE_PACKET"
