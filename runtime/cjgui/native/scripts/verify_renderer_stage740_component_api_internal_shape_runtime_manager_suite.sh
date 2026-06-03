#!/usr/bin/env zsh
#
# Focused suite for stage740. It consumes stage739, verifies the shared
# internal API shape runtime manager, builds runtime/cjgui, and scans stop-lines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE740_TMPDIR:-/private/tmp/cjgui-stage737-stage740/stage740}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage740-component-api-internal-shape-runtime-manager-suite.packet"
STAGE739_SUITE_PACKET="${CJGUI_STAGE740_INPUT_PACKET:-${CJGUI_STAGE739_COMPONENT_API_DEMO_HOST_AUTHORING_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage737-stage740/stage739/stage739-component-api-demo-host-authoring-surface-suite.packet}}"
STAGE739_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage739_component_api_demo_host_authoring_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage740_component_api_internal_shape_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage740-component-api-internal-shape-runtime-manager-owner.log"

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
    echo "cjgui stage740 component api internal shape runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE739_SUITE_PACKET" ]] || ! grep -F "stage739_component_api_demo_host_authoring_surface_suite_passed=true" "$STAGE739_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE739_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage739_component_api_demo_host_authoring_surface_consumed=true" \
  "shared_component_api_internal_shape_runtime_manager_materialized=true" \
  "component_api_internal_authoring_runtime_contract_materialized=true" \
  "component_api_internal_shape_execution_receipt_contract_materialized=true" \
  "cycle_order_component_api_internal_shape_compatibility_authoring_host_runtime_materialized=true" \
  "future_per_demo_public_api_preflight_template_need_reduced=true" \
  "stage741_component_api_authoring_dsl_internal_probe_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage739_component_api_demo_host_authoring_surface_suite_version=1" \
  "component_api_demo_host_authoring_surface_materialized=true" \
  "api_shape_field_inspection_rows_materialized=true" \
  "api_authoring_render_command_receipt_materialized=true" \
  "stage740_component_api_internal_shape_runtime_manager_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE739_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage737_component_state_store_public_api_internal_shape.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage738_component_api_compatibility_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage739_component_api_demo_host_authoring_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage740_component_api_internal_shape_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage740 component api internal shape runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage740 component api internal shape runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage740 component api internal shape runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage740 component api internal shape runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage740 component api internal shape runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage740 component api internal shape runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage740 component api internal shape runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage740_component_api_internal_shape_runtime_manager_suite_version=1"
  echo "stage739_component_api_demo_host_authoring_surface_suite_packet=$STAGE739_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage737_stage740_public_foreign_scan_passed=true"
  echo "stage737_stage740_forbidden_native_render_token_scan_passed=true"
  echo "stage740_protected_path_scan_passed=true"
  echo "next_route=stage741_component_api_authoring_dsl_internal_probe_after_stage740"
  echo "stage740_component_api_internal_shape_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage740 component api internal shape runtime manager suite: route_classification=component_api_internal_shape_runtime_manager_ready"
echo "cjgui stage740 component api internal shape runtime manager suite: suite_packet_path=$SUITE_PACKET"
