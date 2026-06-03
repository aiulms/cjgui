#!/usr/bin/env zsh
#
# Focused suite for stage762. It consumes stage761 and records the
# preview API layout/style descriptor -> text/focus projection bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE762_TMPDIR:-/private/tmp/cjgui-stage761-stage764/stage762}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage762-preview-component-api-text-focus-projection-suite.packet"
STAGE761_SUITE_PACKET="${CJGUI_STAGE762_INPUT_PACKET:-${CJGUI_STAGE761_PREVIEW_COMPONENT_API_LAYOUT_STYLE_CONSUMPTION_SUITE_PACKET:-/private/tmp/cjgui-stage761-stage764/stage761/stage761-preview-component-api-layout-style-consumption-suite.packet}}"
STAGE761_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage761_preview_component_api_layout_style_consumption_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage762_preview_component_api_text_focus_projection_owner.sh"
OWNER_LOG="$TMP_DIR/stage762-preview-component-api-text-focus-projection-owner.log"

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
    echo "cjgui stage762 preview component api text focus projection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE761_SUITE_PACKET" ]] || ! grep -F "stage761_preview_component_api_layout_style_consumption_suite_passed=true" "$STAGE761_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE761_TMPDIR="$TMP_DIR/stage761" zsh "$STAGE761_SUITE_SCRIPT" >/dev/null
  STAGE761_SUITE_PACKET="$TMP_DIR/stage761/stage761-preview-component-api-layout-style-consumption-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage761_preview_component_api_layout_style_consumption_consumed=true" \
  "preview_component_layout_style_descriptors_consumed=true" \
  "preview_component_text_value_projection_materialized=true" \
  "preview_component_caret_selection_projection_materialized=true" \
  "preview_component_focus_traversal_projection_materialized=true" \
  "preview_component_composition_placeholder_projection_materialized=true" \
  "todo_preview_component_api_text_focus_projection_materialized=true" \
  "settings_preview_component_api_text_focus_projection_materialized=true" \
  "ai_generated_settings_preview_component_api_text_focus_projection_materialized=true" \
  "chat_composer_preview_component_api_text_focus_projection_materialized=true" \
  "stage763_preview_component_api_demo_host_inspection_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage761_preview_component_api_layout_style_consumption_suite_passed=true" \
  "preview_component_layout_descriptor_materialized=true" \
  "preview_component_style_token_descriptor_materialized=true"; do
  require_file_fact "$STAGE761_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage762_preview_component_api_text_focus_projection.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage762 preview component api text focus projection suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage762 preview component api text focus projection suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage762 preview component api text focus projection suite: protected production bridge/state path modified" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage762 preview component api text focus projection suite: cjpm unavailable" >&2
  exit 13
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage762 preview component api text focus projection suite: runtime package build failed" >&2
  echo "cjgui stage762 preview component api text focus projection suite: log=$BUILD_LOG" >&2
  exit 14
fi

{
  echo "stage762_preview_component_api_text_focus_projection_suite_version=1"
  echo "stage761_preview_component_api_layout_style_consumption_suite_packet=$STAGE761_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage762_protected_path_scan_passed=true"
  echo "next_route=stage763_preview_component_api_demo_host_inspection_surface_after_stage762"
  echo "stage762_preview_component_api_text_focus_projection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage762 preview component api text focus projection suite: route_classification=public_preview_api_text_focus_projection"
echo "cjgui stage762 preview component api text focus projection suite: suite_packet_path=$SUITE_PACKET"
