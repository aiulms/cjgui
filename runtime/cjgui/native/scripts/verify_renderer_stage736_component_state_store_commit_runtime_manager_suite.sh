#!/usr/bin/env zsh
#
# Focused suite for stage736. It consumes stage735, verifies the shared commit
# runtime manager, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE736_TMPDIR:-/private/tmp/cjgui-stage733-stage736/stage736}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage736-component-state-store-commit-runtime-manager-suite.packet"
STAGE735_SUITE_PACKET="${CJGUI_STAGE736_INPUT_PACKET:-${CJGUI_STAGE735_COMPONENT_VISUAL_STATE_STORE_COMMIT_HOST_INSPECTION_UI_SUITE_PACKET:-/private/tmp/cjgui-stage733-stage736/stage735/stage735-component-visual-state-store-commit-host-inspection-ui-suite.packet}}"
STAGE735_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage735_component_visual_state_store_commit_host_inspection_ui_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage736_component_state_store_commit_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage736-component-state-store-commit-runtime-manager-owner.log"

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
    echo "cjgui stage736 component state store commit runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE735_SUITE_PACKET" ]] || ! grep -F "stage735_component_visual_state_store_commit_host_inspection_ui_suite_passed=true" "$STAGE735_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE735_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage735_component_visual_state_store_commit_host_inspection_ui_consumed=true" \
  "shared_component_state_store_commit_runtime_manager_materialized=true" \
  "component_state_store_commit_runtime_contract_materialized=true" \
  "component_state_store_commit_execution_receipt_contract_materialized=true" \
  "cycle_order_resolver_commit_preflight_snapshot_host_inspection_runtime_materialized=true" \
  "future_per_demo_commit_preflight_template_need_reduced=true" \
  "stage737_component_state_store_public_api_internal_shape_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage735_component_visual_state_store_commit_host_inspection_ui_suite_version=1" \
  "commit_demo_host_inspection_ui_surface_materialized=true" \
  "commit_render_command_refresh_receipt_materialized=true" \
  "stage736_component_state_store_commit_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE735_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage733_component_visual_state_store_commit_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage734_component_visual_state_store_commit_rollback_snapshot.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage735_component_visual_state_store_commit_host_inspection_ui.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage736_component_state_store_commit_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage736 component state store commit runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage736 component state store commit runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage736 component state store commit runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage736 component state store commit runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage736 component state store commit runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage736 component state store commit runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage736 component state store commit runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage736_component_state_store_commit_runtime_manager_suite_version=1"
  echo "stage735_component_visual_state_store_commit_host_inspection_ui_suite_packet=$STAGE735_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage733_stage736_public_foreign_scan_passed=true"
  echo "stage733_stage736_forbidden_native_render_token_scan_passed=true"
  echo "stage736_protected_path_scan_passed=true"
  echo "next_route=stage737_component_state_store_public_api_internal_shape_after_stage736"
  echo "stage736_component_state_store_commit_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage736 component state store commit runtime manager suite: route_classification=component_state_store_commit_runtime_manager_ready"
echo "cjgui stage736 component state store commit runtime manager suite: suite_packet_path=$SUITE_PACKET"
