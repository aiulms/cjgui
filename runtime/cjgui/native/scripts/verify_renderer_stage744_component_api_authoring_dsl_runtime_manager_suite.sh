#!/usr/bin/env zsh
#
# Focused suite for stage744. It consumes stage743, verifies the shared
# authoring DSL runtime manager, builds runtime/cjgui, and scans stop-lines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE744_TMPDIR:-/private/tmp/cjgui-stage741-stage744/stage744}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage744-component-api-authoring-dsl-runtime-manager-suite.packet"
STAGE743_SUITE_PACKET="${CJGUI_STAGE744_INPUT_PACKET:-${CJGUI_STAGE743_COMPONENT_API_AUTHORING_DEMO_HOST_PREVIEW_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage741-stage744/stage743/stage743-component-api-authoring-demo-host-preview-surface-suite.packet}}"
STAGE743_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage743_component_api_authoring_demo_host_preview_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage744_component_api_authoring_dsl_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage744-component-api-authoring-dsl-runtime-manager-owner.log"

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
    echo "cjgui stage744 component api authoring dsl runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE743_SUITE_PACKET" ]] || ! grep -F "stage743_component_api_authoring_demo_host_preview_surface_suite_passed=true" "$STAGE743_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE743_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage743_component_api_authoring_demo_host_preview_surface_consumed=true" \
  "shared_component_api_authoring_dsl_runtime_manager_materialized=true" \
  "component_api_authoring_dsl_runtime_contract_materialized=true" \
  "authoring_semantic_tree_execution_receipt_contract_materialized=true" \
  "cycle_order_authoring_dsl_semantic_tree_host_preview_runtime_materialized=true" \
  "future_per_demo_authoring_dsl_template_need_reduced=true" \
  "stage745_component_api_authoring_dsl_ai_generated_ui_dry_run_prepared=true" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage743_component_api_authoring_demo_host_preview_surface_suite_passed=true" \
  "component_api_authoring_demo_host_preview_surface_materialized=true" \
  "host_preview_inspection_rows_materialized=true" \
  "authoring_render_command_preview_receipt_materialized=true" \
  "stage744_component_api_authoring_dsl_runtime_manager_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE743_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage741_component_api_authoring_dsl_internal_probe.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage742_component_api_authoring_semantic_tree_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage743_component_api_authoring_demo_host_preview_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage744_component_api_authoring_dsl_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage744 component api authoring dsl runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage744 component api authoring dsl runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage744 component api authoring dsl runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage744 component api authoring dsl runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage744 component api authoring dsl runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage744 component api authoring dsl runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage744 component api authoring dsl runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage744_component_api_authoring_dsl_runtime_manager_suite_version=1"
  echo "stage743_component_api_authoring_demo_host_preview_surface_suite_packet=$STAGE743_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage741_stage744_public_foreign_scan_passed=true"
  echo "stage741_stage744_forbidden_native_render_token_scan_passed=true"
  echo "stage744_protected_path_scan_passed=true"
  echo "next_route=stage745_component_api_authoring_dsl_ai_generated_ui_dry_run_after_stage744"
  echo "stage744_component_api_authoring_dsl_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage744 component api authoring dsl runtime manager suite: route_classification=component_api_authoring_dsl_runtime_manager_ready"
echo "cjgui stage744 component api authoring dsl runtime manager suite: suite_packet_path=$SUITE_PACKET"
