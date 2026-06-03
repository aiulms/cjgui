#!/usr/bin/env zsh
#
# Focused suite for stage763. It consumes stage762 and records the
# checkable demo-host inspection surface for public preview visual descriptors.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE763_TMPDIR:-/private/tmp/cjgui-stage761-stage764/stage763}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage763-preview-component-api-demo-host-inspection-surface-suite.packet"
STAGE762_SUITE_PACKET="${CJGUI_STAGE763_INPUT_PACKET:-${CJGUI_STAGE762_PREVIEW_COMPONENT_API_TEXT_FOCUS_PROJECTION_SUITE_PACKET:-/private/tmp/cjgui-stage761-stage764/stage762/stage762-preview-component-api-text-focus-projection-suite.packet}}"
STAGE762_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage762_preview_component_api_text_focus_projection_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage763_preview_component_api_demo_host_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage763-preview-component-api-demo-host-inspection-surface-owner.log"

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
    echo "cjgui stage763 preview component api demo host inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE762_SUITE_PACKET" ]] || ! grep -F "stage762_preview_component_api_text_focus_projection_suite_passed=true" "$STAGE762_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE762_TMPDIR="$TMP_DIR/stage762" zsh "$STAGE762_SUITE_SCRIPT" >/dev/null
  STAGE762_SUITE_PACKET="$TMP_DIR/stage762/stage762-preview-component-api-text-focus-projection-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage762_preview_component_api_text_focus_projection_consumed=true" \
  "preview_component_api_host_inspection_rows_materialized=true" \
  "preview_component_api_render_command_preview_receipt_materialized=true" \
  "preview_component_api_semantic_diff_receipt_materialized=true" \
  "preview_component_api_result_surface_refresh_materialized=true" \
  "todo_preview_component_api_demo_host_inspection_surface_materialized=true" \
  "settings_preview_component_api_demo_host_inspection_surface_materialized=true" \
  "ai_generated_settings_preview_component_api_demo_host_inspection_surface_materialized=true" \
  "chat_composer_preview_component_api_demo_host_inspection_surface_materialized=true" \
  "stage764_preview_component_api_visual_resolver_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage762_preview_component_api_text_focus_projection_suite_passed=true" \
  "preview_component_text_value_projection_materialized=true" \
  "preview_component_focus_traversal_projection_materialized=true"; do
  require_file_fact "$STAGE762_SUITE_PACKET" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage763 preview component api demo host inspection surface suite: protected production bridge/state path modified" >&2
  exit 10
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage763 preview component api demo host inspection surface suite: cjpm unavailable" >&2
  exit 11
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage763 preview component api demo host inspection surface suite: runtime package build failed" >&2
  echo "cjgui stage763 preview component api demo host inspection surface suite: log=$BUILD_LOG" >&2
  exit 12
fi

{
  echo "stage763_preview_component_api_demo_host_inspection_surface_suite_version=1"
  echo "stage762_preview_component_api_text_focus_projection_suite_packet=$STAGE762_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage763_protected_path_scan_passed=true"
  echo "next_route=stage764_preview_component_api_visual_resolver_runtime_manager_after_stage763"
  echo "stage763_preview_component_api_demo_host_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage763 preview component api demo host inspection surface suite: route_classification=public_preview_api_demo_host_inspection"
echo "cjgui stage763 preview component api demo host inspection surface suite: suite_packet_path=$SUITE_PACKET"
