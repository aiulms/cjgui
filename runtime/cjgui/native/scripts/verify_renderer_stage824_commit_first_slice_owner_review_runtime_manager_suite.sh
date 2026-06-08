#!/usr/bin/env zsh
#
# Focused suite for stage824. It consumes stage823, builds runtime/cjgui, and
# records the shared owner review runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE824_TMPDIR:-/private/tmp/cjgui-stage821-stage824/stage824}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage824-commit-first-slice-owner-review-runtime-manager-suite.packet"
STAGE823_SUITE_PACKET="${CJGUI_STAGE824_INPUT_PACKET:-${CJGUI_STAGE823_COMMIT_FIRST_SLICE_OWNER_REVIEW_DEMO_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage821-stage824/stage823/stage823-commit-first-slice-owner-review-demo-host-surface-suite.packet}}"
STAGE823_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage823_commit_first_slice_owner_review_demo_host_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage824_commit_first_slice_owner_review_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage824-commit-first-slice-owner-review-runtime-manager-owner.log"

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
    echo "cjgui stage824 commit first-slice owner review runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE823_SUITE_PACKET" ]] || ! grep -F "stage823_commit_first_slice_owner_review_demo_host_surface_suite_passed=true" "$STAGE823_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE823_TMPDIR="$TMP_DIR/stage823" zsh "$STAGE823_SUITE_SCRIPT" >/dev/null
  STAGE823_SUITE_PACKET="$TMP_DIR/stage823/stage823-commit-first-slice-owner-review-demo-host-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage821_commit_first_slice_owner_review_gate_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage821_commit_first_slice_owner_review_gate_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage822_commit_first_slice_review_decision_router_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage822_commit_first_slice_review_decision_router_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage823_commit_first_slice_owner_review_demo_host_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage823_commit_first_slice_owner_review_demo_host_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage824_commit_first_slice_owner_review_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage824_commit_first_slice_owner_review_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage823_commit_first_slice_owner_review_demo_host_surface_consumed=true" \
  "stage822_commit_first_slice_review_decision_router_consumed_transitively=true" \
  "stage821_commit_first_slice_owner_review_gate_consumed_transitively=true" \
  "stage820_commit_first_slice_host_inspection_runtime_presenter_consumed_transitively=true" \
  "shared_owner_review_runtime_manager_materialized=true" \
  "owner_review_runtime_contract_materialized=true" \
  "owner_review_execution_receipt_contract_materialized=true" \
  "cycle_order_owner_review_gate_decision_demo_runtime_materialized=true" \
  "file_browser_owner_review_runtime_surface_materialized=true" \
  "owner_review_runtime_manager_bound_to_stage821_gate=true" \
  "owner_review_runtime_manager_bound_to_stage822_decision_router=true" \
  "owner_review_runtime_manager_bound_to_stage823_demo_surface=true" \
  "future_per_demo_owner_review_template_need_reduced=true" \
  "stage825_commit_first_slice_publication_gate_after_stage824_prepared=true" \
  "new_public_surface_added=false" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage823_commit_first_slice_owner_review_demo_host_surface_suite_passed=true" \
  "file_browser_commit_first_slice_owner_review_surface_materialized=true" \
  "commit_first_slice_owner_review_result_surface_materialized=true"; do
  require_file_fact "$STAGE823_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage821_commit_first_slice_owner_review_gate.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage822_commit_first_slice_review_decision_router.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage823_commit_first_slice_owner_review_demo_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage824_commit_first_slice_owner_review_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage824 commit first-slice owner review runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage824 commit first-slice owner review runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage824 commit first-slice owner review runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(21|22|23|24)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage824 commit first-slice owner review runtime manager suite: unexpected stage821-824 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage824 commit first-slice owner review runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage824 commit first-slice owner review runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage824 commit first-slice owner review runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage824 commit first-slice owner review runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage824_commit_first_slice_owner_review_runtime_manager_suite_version=1"
  echo "stage823_suite_packet=$STAGE823_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage821_stage824_public_declaration_scan_passed=true"
  echo "stage821_stage824_forbidden_native_render_token_scan_passed=true"
  echo "stage824_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage825_commit_first_slice_publication_gate_after_stage824"
  echo "stage824_commit_first_slice_owner_review_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage824 commit first-slice owner review runtime manager suite: route_classification=commit_owner_review_runtime_manager"
echo "cjgui stage824 commit first-slice owner review runtime manager suite: suite_packet_path=$SUITE_PACKET"
