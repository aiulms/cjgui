#!/usr/bin/env zsh
#
# Focused suite for stage784. It consumes stage783, builds runtime/cjgui, and
# records the shared preview component API commit inspection runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE784_TMPDIR:-/private/tmp/cjgui-stage781-stage784/stage784}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage784-preview-component-api-commit-inspection-runtime-manager-suite.packet"
STAGE783_SUITE_PACKET="${CJGUI_STAGE784_INPUT_PACKET:-${CJGUI_STAGE783_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_RESULT_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage781-stage784/stage783/stage783-preview-component-api-commit-inspection-result-surface-suite.packet}}"
STAGE783_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage783_preview_component_api_commit_inspection_result_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage784_preview_component_api_commit_inspection_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage784-preview-component-api-commit-inspection-runtime-manager-owner.log"

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
    echo "cjgui stage784 preview component api commit inspection runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE783_SUITE_PACKET" ]] || ! grep -F "stage783_preview_component_api_commit_inspection_result_surface_suite_passed=true" "$STAGE783_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE783_TMPDIR="$TMP_DIR/stage783" zsh "$STAGE783_SUITE_SCRIPT" >/dev/null
  STAGE783_SUITE_PACKET="$TMP_DIR/stage783/stage783-preview-component-api-commit-inspection-result-surface-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage783_preview_component_api_commit_inspection_result_surface_consumed=true" \
  "stage782_preview_component_api_commit_inspection_review_actions_consumed_transitively=true" \
  "stage781_preview_component_api_commit_inspection_ui_consumed_transitively=true" \
  "stage780_preview_component_api_state_store_commit_runtime_manager_consumed_transitively=true" \
  "shared_preview_component_api_commit_inspection_runtime_manager_materialized=true" \
  "preview_component_api_commit_inspection_runtime_contract_materialized=true" \
  "preview_component_api_commit_inspection_execution_receipt_contract_materialized=true" \
  "cycle_order_preview_api_commit_inspection_ui_review_result_runtime_materialized=true" \
  "chat_composer_preview_component_api_commit_inspection_runtime_surface_materialized=true" \
  "commit_inspection_runtime_manager_bound_to_stage781_ui=true" \
  "commit_inspection_runtime_manager_bound_to_stage782_review_actions=true" \
  "commit_inspection_runtime_manager_bound_to_stage783_result_surface=true" \
  "future_per_demo_commit_inspection_template_need_reduced=true" \
  "stage785_preview_component_api_commit_inspection_public_preview_contract_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage783_preview_component_api_commit_inspection_result_surface_suite_passed=true" \
  "commit_inspection_execution_receipt_materialized=true" \
  "stage784_preview_component_api_commit_inspection_runtime_manager_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE783_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage781_preview_component_api_commit_inspection_ui.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage782_preview_component_api_commit_inspection_review_actions.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage783_preview_component_api_commit_inspection_result_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage784_preview_component_api_commit_inspection_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage784 preview component api commit inspection runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage784 preview component api commit inspection runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage784 preview component api commit inspection runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage78(1|2|3|4).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage784 preview component api commit inspection runtime manager suite: unexpected stage781-784 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage784 preview component api commit inspection runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage784 preview component api commit inspection runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage784 preview component api commit inspection runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage784 preview component api commit inspection runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage784_preview_component_api_commit_inspection_runtime_manager_suite_version=1"
  echo "stage783_preview_component_api_commit_inspection_result_surface_suite_packet=$STAGE783_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage781_stage784_public_declaration_scan_passed=true"
  echo "stage781_stage784_forbidden_native_render_token_scan_passed=true"
  echo "stage784_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage785_preview_component_api_commit_inspection_public_preview_contract_after_stage784"
  echo "stage784_preview_component_api_commit_inspection_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage784 preview component api commit inspection runtime manager suite: route_classification=preview_api_commit_inspection_runtime_manager"
echo "cjgui stage784 preview component api commit inspection runtime manager suite: suite_packet_path=$SUITE_PACKET"
