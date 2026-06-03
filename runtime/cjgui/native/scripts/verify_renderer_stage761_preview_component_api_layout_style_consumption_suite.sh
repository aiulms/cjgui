#!/usr/bin/env zsh
#
# Focused suite for stage761. It consumes stage760 and records the
# experimental public preview API -> layout/style descriptor bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE761_TMPDIR:-/private/tmp/cjgui-stage761-stage764/stage761}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage761-preview-component-api-layout-style-consumption-suite.packet"
STAGE760_SUITE_PACKET="${CJGUI_STAGE761_INPUT_PACKET:-${CJGUI_STAGE760_MINIMAL_PUBLIC_PREVIEW_API_PUBLIC_SCAN_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage757-stage760/stage760/stage760-minimal-public-preview-api-public-scan-contract-suite.packet}}"
STAGE760_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage760_minimal_public_preview_api_public_scan_contract_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage761_preview_component_api_layout_style_consumption_owner.sh"
OWNER_LOG="$TMP_DIR/stage761-preview-component-api-layout-style-consumption-owner.log"

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
    echo "cjgui stage761 preview component api layout style consumption suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE760_SUITE_PACKET" ]] || ! grep -F "stage760_minimal_public_preview_api_public_scan_contract_suite_passed=true" "$STAGE760_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE760_TMPDIR="$TMP_DIR/stage760" zsh "$STAGE760_SUITE_SCRIPT" >/dev/null
  STAGE760_SUITE_PACKET="$TMP_DIR/stage760/stage760-minimal-public-preview-api-public-scan-contract-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage760_minimal_public_preview_api_public_scan_contract_consumed=true" \
  "cjguiExperimentalComponentPreviewApiReady_consumed=true" \
  "preview_component_layout_descriptor_materialized=true" \
  "preview_component_style_token_descriptor_materialized=true" \
  "todo_preview_component_api_layout_style_surface_materialized=true" \
  "settings_preview_component_api_layout_style_surface_materialized=true" \
  "ai_generated_settings_preview_component_api_layout_style_surface_materialized=true" \
  "chat_composer_preview_component_api_layout_style_surface_materialized=true" \
  "stage762_preview_component_api_text_focus_projection_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage760_minimal_public_preview_api_public_scan_contract_suite_passed=true" \
  "public_surface_cjguiExperimentalComponentPreviewApiReady_listed=true" \
  "new_public_surface=cjguiExperimentalComponentPreviewApiReady" \
  "new_public_surface_stability=experimental_preview"; do
  require_file_fact "$STAGE760_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage761_preview_component_api_layout_style_consumption.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage761 preview component api layout style consumption suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage761 preview component api layout style consumption suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|presentDrawable|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage761 preview component api layout style consumption suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage761 preview component api layout style consumption suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage761 preview component api layout style consumption suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage761 preview component api layout style consumption suite: runtime package build failed" >&2
  echo "cjgui stage761 preview component api layout style consumption suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage761_preview_component_api_layout_style_consumption_suite_version=1"
  echo "stage760_minimal_public_preview_api_public_scan_contract_suite_packet=$STAGE760_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage761_forbidden_native_render_token_scan_passed=true"
  echo "stage761_protected_path_scan_passed=true"
  echo "next_route=stage762_preview_component_api_text_focus_projection_after_stage761"
  echo "stage761_preview_component_api_layout_style_consumption_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage761 preview component api layout style consumption suite: route_classification=public_preview_api_visual_descriptor"
echo "cjgui stage761 preview component api layout style consumption suite: suite_packet_path=$SUITE_PACKET"
