#!/usr/bin/env zsh
#
# Focused suite for stage731. It consumes stage730 and verifies host inspection,
# result surface refresh, RenderCommand receipt, and semantic diff receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE731_TMPDIR:-/private/tmp/cjgui-stage729-stage732/stage731}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage731-component-visual-state-store-resolver-host-inspection-surface-suite.packet"
STAGE730_SUITE_PACKET="${CJGUI_STAGE731_INPUT_PACKET:-${CJGUI_STAGE730_COMPONENT_VISUAL_STATE_STORE_TEXT_SELECTION_PROJECTION_SUITE_PACKET:-/private/tmp/cjgui-stage729-stage732/stage730/stage730-component-visual-state-store-text-selection-projection-suite.packet}}"
STAGE730_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage730_component_visual_state_store_text_selection_projection_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage731_component_visual_state_store_resolver_host_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage731-component-visual-state-store-resolver-host-inspection-surface-owner.log"

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
    echo "cjgui stage731 component visual state store resolver host inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE730_SUITE_PACKET" ]]; then
  zsh "$STAGE730_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage730_component_visual_state_store_text_selection_projection_consumed=true" \
  "stage729_component_visual_state_store_layout_style_focus_resolver_consumed_transitively=true" \
  "visual_state_store_resolver_host_inspection_surface_materialized=true" \
  "visual_state_store_resolver_result_surface_refresh_materialized=true" \
  "visual_state_store_resolver_render_command_receipt_materialized=true" \
  "visual_state_store_resolver_semantic_diff_receipt_materialized=true" \
  "stage732_component_visual_state_store_resolver_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage730_component_visual_state_store_text_selection_projection_suite_version=1" \
  "shared_visual_state_store_text_model_projection_materialized=true" \
  "visual_state_store_composition_placeholder_ledger_materialized=true" \
  "stage731_component_visual_state_store_resolver_host_inspection_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE730_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage730_component_visual_state_store_text_selection_projection.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage731_component_visual_state_store_resolver_host_inspection_surface.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage731 component visual state store resolver host inspection surface suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage731 component visual state store resolver host inspection surface suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage731 component visual state store resolver host inspection surface suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage731 component visual state store resolver host inspection surface suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage731 component visual state store resolver host inspection surface suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage731 component visual state store resolver host inspection surface suite: runtime package build failed" >&2
  echo "cjgui stage731 component visual state store resolver host inspection surface suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage731_component_visual_state_store_resolver_host_inspection_surface_suite_version=1"
  echo "stage730_component_visual_state_store_text_selection_projection_suite_packet=$STAGE730_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage731_public_foreign_scan_passed=true"
  echo "stage731_forbidden_native_render_token_scan_passed=true"
  echo "stage731_protected_path_scan_passed=true"
  echo "next_route=stage732_component_visual_state_store_resolver_runtime_manager_after_stage731"
  echo "stage731_component_visual_state_store_resolver_host_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage731 component visual state store resolver host inspection surface suite: route_classification=component_visual_state_store_resolver_host_inspection_surface_ready"
echo "cjgui stage731 component visual state store resolver host inspection surface suite: suite_packet_path=$SUITE_PACKET"
