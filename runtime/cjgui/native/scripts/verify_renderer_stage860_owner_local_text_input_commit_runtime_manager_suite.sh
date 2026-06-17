#!/usr/bin/env zsh
#
# Focused suite for stage860. It consumes stage859, builds runtime/cjgui, and
# records the shared owner-local text-input commit runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE860_TMPDIR:-/private/tmp/cjgui-stage857-stage860/stage860}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage860-owner-local-text-input-commit-runtime-manager-suite.packet"
STAGE859_SUITE_PACKET="${CJGUI_STAGE860_INPUT_PACKET:-${CJGUI_STAGE859_OWNER_LOCAL_TEXT_INPUT_COMMIT_RESULT_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage857-stage860/stage859/stage859-owner-local-text-input-commit-result-surface-suite.packet}}"
STAGE859_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage859_owner_local_text_input_commit_result_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage860_owner_local_text_input_commit_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage860-owner-local-text-input-commit-runtime-manager-owner.log"

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
    echo "cjgui stage860 owner-local text input commit runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE859_SUITE_PACKET" ]] || ! grep -F "stage859_owner_local_text_input_commit_result_surface_suite_passed=true" "$STAGE859_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE859_TMPDIR="$TMP_DIR/stage859" zsh "$STAGE859_SUITE_SCRIPT" >/dev/null
  STAGE859_SUITE_PACKET="$TMP_DIR/stage859/stage859-owner-local-text-input-commit-result-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage857_owner_local_text_input_commit_dry_run_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage857_owner_local_text_input_commit_dry_run_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage858_owner_local_text_input_state_store_commit_snapshot_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage858_owner_local_text_input_state_store_commit_snapshot_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage859_owner_local_text_input_commit_result_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage859_owner_local_text_input_commit_result_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage860_owner_local_text_input_commit_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage860_owner_local_text_input_commit_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage859_owner_local_text_input_commit_result_surface_consumed=true" \
  "stage858_owner_local_text_input_state_store_commit_snapshot_consumed_transitively=true" \
  "stage857_owner_local_text_input_commit_dry_run_consumed_transitively=true" \
  "stage856_text_input_commit_runtime_manager_consumed_transitively=true" \
  "shared_owner_local_text_input_commit_runtime_manager_materialized=true" \
  "owner_local_text_input_commit_runtime_contract_materialized=true" \
  "owner_local_text_input_commit_execution_receipt_contract_materialized=true" \
  "cycle_order_owner_local_text_input_commit_dry_run_state_store_result_runtime_materialized=true" \
  "file_browser_owner_local_text_input_commit_runtime_surface_materialized=true" \
  "owner_local_text_input_commit_runtime_manager_bound_to_stage857_dry_run=true" \
  "owner_local_text_input_commit_runtime_manager_bound_to_stage858_state_store_commit_snapshot=true" \
  "owner_local_text_input_commit_runtime_manager_bound_to_stage859_result_surface=true" \
  "owner_local_text_input_commit_first_slice_readiness_materialized=true" \
  "owner_local_text_input_commit_first_slice_materialized=true" \
  "owner_local_text_input_commit_applied=true" \
  "future_per_demo_owner_local_text_input_commit_template_need_reduced=true" \
  "stage861_text_input_owner_acceptance_review_after_owner_local_commit_prepared=true" \
  "text_input_commit_committed=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage859_owner_local_text_input_commit_result_surface_suite_passed=true" \
  "file_browser_owner_local_text_input_commit_result_surface_materialized=true" \
  "owner_local_text_input_commit_applied=true" \
  "stage860_owner_local_text_input_commit_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE859_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage857_owner_local_text_input_commit_dry_run.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage858_owner_local_text_input_state_store_commit_snapshot.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage859_owner_local_text_input_commit_result_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage860_owner_local_text_input_commit_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage860 owner-local text input commit runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage860 owner-local text input commit runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage860 owner-local text input commit runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage86(0)|runtime_renderer_stage85(7|8|9).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage860 owner-local text input commit runtime manager suite: unexpected stage857-860 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage860 owner-local text input commit runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage860 owner-local text input commit runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage860 owner-local text input commit runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage860 owner-local text input commit runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage860_owner_local_text_input_commit_runtime_manager_suite_version=1"
  echo "stage859_suite_packet=$STAGE859_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage857_stage860_public_declaration_scan_passed=true"
  echo "stage857_stage860_forbidden_native_render_token_scan_passed=true"
  echo "stage860_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage861_text_input_owner_acceptance_review_after_stage860"
  echo "stage860_owner_local_text_input_commit_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage860 owner-local text input commit runtime manager suite: route_classification=owner_local_text_input_commit_runtime_manager"
echo "cjgui stage860 owner-local text input commit runtime manager suite: suite_packet_path=$SUITE_PACKET"
