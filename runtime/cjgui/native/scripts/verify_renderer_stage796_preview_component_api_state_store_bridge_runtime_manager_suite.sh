#!/usr/bin/env zsh
#
# Focused suite for stage796. It consumes stage795, builds runtime/cjgui, and
# records the shared component state-store bridge runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE796_TMPDIR:-/private/tmp/cjgui-stage793-stage796/stage796}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage796-preview-component-api-state-store-bridge-runtime-manager-suite.packet"
STAGE795_SUITE_PACKET="${CJGUI_STAGE796_INPUT_PACKET:-${CJGUI_STAGE795_PREVIEW_COMPONENT_API_STATE_STORE_INSPECTION_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage793-stage796/stage795/stage795-preview-component-api-state-store-inspection-surface-suite.packet}}"
STAGE795_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage795_preview_component_api_state_store_inspection_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage796_preview_component_api_state_store_bridge_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage796-preview-component-api-state-store-bridge-runtime-manager-owner.log"

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
    echo "cjgui stage796 preview component api state-store bridge runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE795_SUITE_PACKET" ]] || ! grep -F "stage795_preview_component_api_state_store_inspection_surface_suite_passed=true" "$STAGE795_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE795_TMPDIR="$TMP_DIR/stage795" zsh "$STAGE795_SUITE_SCRIPT" >/dev/null
  STAGE795_SUITE_PACKET="$TMP_DIR/stage795/stage795-preview-component-api-state-store-inspection-surface-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage795_preview_component_api_state_store_inspection_surface_consumed=true" \
  "stage794_preview_component_api_state_store_dry_run_executor_consumed_transitively=true" \
  "stage793_preview_component_api_commit_decision_state_store_bridge_consumed_transitively=true" \
  "shared_component_state_store_bridge_runtime_manager_materialized=true" \
  "component_state_store_bridge_runtime_contract_materialized=true" \
  "component_state_store_bridge_execution_receipt_contract_materialized=true" \
  "cycle_order_commit_decision_state_store_dry_run_inspection_runtime_materialized=true" \
  "file_browser_component_state_store_bridge_runtime_surface_materialized=true" \
  "state_store_bridge_runtime_manager_bound_to_stage793_bridge=true" \
  "state_store_bridge_runtime_manager_bound_to_stage794_dry_run_executor=true" \
  "state_store_bridge_runtime_manager_bound_to_stage795_inspection_surface=true" \
  "future_per_demo_state_store_bridge_template_need_reduced=true" \
  "stage797_preview_component_api_state_store_commit_admission_preview_prepared=true" \
  "new_public_surface_added=false" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage795_preview_component_api_state_store_inspection_surface_suite_passed=true" \
  "file_browser_state_store_dry_run_surface_materialized=true" \
  "stage796_preview_component_api_state_store_bridge_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE795_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage793_preview_component_api_commit_decision_state_store_bridge.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage794_preview_component_api_state_store_dry_run_executor.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage795_preview_component_api_state_store_inspection_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage796_preview_component_api_state_store_bridge_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage796 preview component api state-store bridge runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage796 preview component api state-store bridge runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage796 preview component api state-store bridge runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage79(3|4|5|6)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage796 preview component api state-store bridge runtime manager suite: unexpected stage793-796 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage796 preview component api state-store bridge runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage796 preview component api state-store bridge runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage796 preview component api state-store bridge runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage796 preview component api state-store bridge runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage796_preview_component_api_state_store_bridge_runtime_manager_suite_version=1"
  echo "stage795_preview_component_api_state_store_inspection_surface_suite_packet=$STAGE795_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage793_stage796_public_declaration_scan_passed=true"
  echo "stage793_stage796_forbidden_native_render_token_scan_passed=true"
  echo "stage796_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage797_preview_component_api_state_store_commit_admission_preview_after_stage796"
  echo "stage796_preview_component_api_state_store_bridge_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage796 preview component api state-store bridge runtime manager suite: route_classification=component_state_store_bridge_runtime_manager"
echo "cjgui stage796 preview component api state-store bridge runtime manager suite: suite_packet_path=$SUITE_PACKET"
