#!/usr/bin/env zsh
#
# Focused suite for stage820. It consumes stage819, builds runtime/cjgui, and
# records the shared host inspection runtime presenter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE820_TMPDIR:-/private/tmp/cjgui-stage817-stage820/stage820}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage820-commit-first-slice-host-inspection-runtime-presenter-suite.packet"
STAGE819_SUITE_PACKET="${CJGUI_STAGE820_INPUT_PACKET:-${CJGUI_STAGE819_COMMIT_FIRST_SLICE_DEMO_HOST_INSPECTION_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage817-stage820/stage819/stage819-commit-first-slice-demo-host-inspection-surface-suite.packet}}"
STAGE819_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage819_commit_first_slice_demo_host_inspection_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage820_commit_first_slice_host_inspection_runtime_presenter_owner.sh"
OWNER_LOG="$TMP_DIR/stage820-commit-first-slice-host-inspection-runtime-presenter-owner.log"

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
    echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE819_SUITE_PACKET" ]] || ! grep -F "stage819_commit_first_slice_demo_host_inspection_surface_suite_passed=true" "$STAGE819_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE819_TMPDIR="$TMP_DIR/stage819" zsh "$STAGE819_SUITE_SCRIPT" >/dev/null
  STAGE819_SUITE_PACKET="$TMP_DIR/stage819/stage819-commit-first-slice-demo-host-inspection-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage817_commit_first_slice_host_inspection_lens_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage817_commit_first_slice_host_inspection_lens_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage818_commit_first_slice_inspection_filter_controller_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage818_commit_first_slice_inspection_filter_controller_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage819_commit_first_slice_demo_host_inspection_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage819_commit_first_slice_demo_host_inspection_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage820_commit_first_slice_host_inspection_runtime_presenter_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage820_commit_first_slice_host_inspection_runtime_presenter_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage819_commit_first_slice_demo_host_inspection_surface_consumed=true" \
  "stage818_commit_first_slice_inspection_filter_controller_consumed_transitively=true" \
  "stage817_commit_first_slice_host_inspection_lens_consumed_transitively=true" \
  "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_consumed_transitively=true" \
  "shared_commit_host_inspection_runtime_presenter_materialized=true" \
  "commit_host_inspection_runtime_contract_materialized=true" \
  "commit_host_inspection_execution_receipt_contract_materialized=true" \
  "cycle_order_commit_host_inspection_lens_filter_surface_presenter_materialized=true" \
  "file_browser_commit_inspection_runtime_surface_materialized=true" \
  "commit_host_inspection_runtime_presenter_bound_to_stage817_lens=true" \
  "commit_host_inspection_runtime_presenter_bound_to_stage818_filter_controller=true" \
  "commit_host_inspection_runtime_presenter_bound_to_stage819_demo_surface=true" \
  "future_per_demo_commit_host_inspection_template_need_reduced=true" \
  "stage821_commit_first_slice_owner_review_gate_after_stage820_prepared=true" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage819_commit_first_slice_demo_host_inspection_surface_suite_passed=true" \
  "file_browser_commit_first_slice_inspection_surface_materialized=true" \
  "commit_first_slice_host_inspection_result_surface_materialized=true"; do
  require_file_fact "$STAGE819_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage817_commit_first_slice_host_inspection_lens.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage818_commit_first_slice_inspection_filter_controller.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage819_commit_first_slice_demo_host_inspection_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage820_commit_first_slice_host_inspection_runtime_presenter.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(17|18|19|20)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: unexpected stage817-820 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: runtime package build failed" >&2
  echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage820_commit_first_slice_host_inspection_runtime_presenter_suite_version=1"
  echo "stage819_suite_packet=$STAGE819_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage817_stage820_public_declaration_scan_passed=true"
  echo "stage817_stage820_forbidden_native_render_token_scan_passed=true"
  echo "stage820_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage821_commit_first_slice_owner_review_gate_after_stage820"
  echo "stage820_commit_first_slice_host_inspection_runtime_presenter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: route_classification=commit_host_inspection_runtime_presenter"
echo "cjgui stage820 commit first-slice host inspection runtime presenter suite: suite_packet_path=$SUITE_PACKET"
