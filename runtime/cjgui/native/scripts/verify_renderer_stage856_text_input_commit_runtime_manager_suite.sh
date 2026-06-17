#!/usr/bin/env zsh
#
# Focused suite for stage856. It consumes stage855, builds runtime/cjgui, and
# records the shared text-input commit runtime manager / commit first-slice readiness.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE856_TMPDIR:-/private/tmp/cjgui-stage853-stage856/stage856}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage856-text-input-commit-runtime-manager-suite.packet"
STAGE855_SUITE_PACKET="${CJGUI_STAGE856_INPUT_PACKET:-${CJGUI_STAGE855_TEXT_INPUT_COMMIT_INSPECTION_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage853-stage856/stage855/stage855-text-input-commit-inspection-surface-suite.packet}}"
STAGE855_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage855_text_input_commit_inspection_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage856_text_input_commit_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage856-text-input-commit-runtime-manager-owner.log"

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
    echo "cjgui stage856 text input commit runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE855_SUITE_PACKET" ]] || ! grep -F "stage855_text_input_commit_inspection_surface_suite_passed=true" "$STAGE855_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE855_TMPDIR="$TMP_DIR/stage855" zsh "$STAGE855_SUITE_SCRIPT" >/dev/null
  STAGE855_SUITE_PACKET="$TMP_DIR/stage855/stage855-text-input-commit-inspection-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage853_text_input_commit_preflight_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage853_text_input_commit_preflight_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage854_text_input_commit_rollback_snapshot_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage854_text_input_commit_rollback_snapshot_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage855_text_input_commit_inspection_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage855_text_input_commit_inspection_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage856_text_input_commit_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage856_text_input_commit_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage855_text_input_commit_inspection_surface_consumed=true" \
  "stage854_text_input_commit_rollback_snapshot_consumed_transitively=true" \
  "stage853_text_input_commit_preflight_consumed_transitively=true" \
  "shared_text_input_commit_runtime_manager_materialized=true" \
  "text_input_commit_runtime_contract_materialized=true" \
  "text_input_commit_execution_receipt_contract_materialized=true" \
  "cycle_order_text_input_commit_preflight_rollback_inspection_runtime_materialized=true" \
  "file_browser_text_input_commit_runtime_surface_materialized=true" \
  "text_input_commit_runtime_manager_bound_to_stage853_commit_preflight=true" \
  "text_input_commit_runtime_manager_bound_to_stage854_rollback_snapshot=true" \
  "text_input_commit_runtime_manager_bound_to_stage855_inspection_surface=true" \
  "text_input_commit_first_slice_readiness_materialized=true" \
  "future_per_demo_text_input_commit_template_need_reduced=true" \
  "stage857_owner_local_text_input_commit_dry_run_prepared=true" \
  "owner_local_commit_first_slice_ready=true" \
  "text_input_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage855_text_input_commit_inspection_surface_suite_passed=true" \
  "file_browser_text_input_commit_inspection_surface_materialized=true" \
  "stage856_text_input_commit_runtime_manager_prepared=true" \
  "text_input_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE855_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage853_text_input_commit_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage854_text_input_commit_rollback_snapshot.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage855_text_input_commit_inspection_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage856_text_input_commit_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage856 text input commit runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage856 text input commit runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage856 text input commit runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage85(3|4|5|6).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage856 text input commit runtime manager suite: unexpected stage853-856 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage856 text input commit runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage856 text input commit runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage856 text input commit runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage856 text input commit runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage856_text_input_commit_runtime_manager_suite_version=1"
  echo "stage855_suite_packet=$STAGE855_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage853_stage856_public_declaration_scan_passed=true"
  echo "stage853_stage856_forbidden_native_render_token_scan_passed=true"
  echo "stage856_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage857_owner_local_text_input_commit_dry_run_after_stage856"
  echo "stage856_text_input_commit_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage856 text input commit runtime manager suite: route_classification=text_input_commit_runtime_manager"
echo "cjgui stage856 text input commit runtime manager suite: suite_packet_path=$SUITE_PACKET"
