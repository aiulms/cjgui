#!/usr/bin/env zsh
#
# Focused suite for stage828. It consumes stage827, builds runtime/cjgui, and
# records the shared publication runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE828_TMPDIR:-/private/tmp/cjgui-stage825-stage828/stage828}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage828-commit-first-slice-publication-runtime-manager-suite.packet"
STAGE827_SUITE_PACKET="${CJGUI_STAGE828_INPUT_PACKET:-${CJGUI_STAGE827_COMMIT_FIRST_SLICE_PUBLICATION_DEMO_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage825-stage828/stage827/stage827-commit-first-slice-publication-demo-host-surface-suite.packet}}"
STAGE827_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage827_commit_first_slice_publication_demo_host_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage828_commit_first_slice_publication_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage828-commit-first-slice-publication-runtime-manager-owner.log"

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
    echo "cjgui stage828 commit first-slice publication runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE827_SUITE_PACKET" ]] || ! grep -F "stage827_commit_first_slice_publication_demo_host_surface_suite_passed=true" "$STAGE827_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE827_TMPDIR="$TMP_DIR/stage827" zsh "$STAGE827_SUITE_SCRIPT" >/dev/null
  STAGE827_SUITE_PACKET="$TMP_DIR/stage827/stage827-commit-first-slice-publication-demo-host-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage825_commit_first_slice_publication_gate_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage825_commit_first_slice_publication_gate_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage826_commit_first_slice_publication_visibility_rehearsal_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage826_commit_first_slice_publication_visibility_rehearsal_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage827_commit_first_slice_publication_demo_host_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage827_commit_first_slice_publication_demo_host_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage828_commit_first_slice_publication_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage828_commit_first_slice_publication_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage827_commit_first_slice_publication_demo_host_surface_consumed=true" \
  "stage826_commit_first_slice_publication_visibility_rehearsal_consumed_transitively=true" \
  "stage825_commit_first_slice_publication_gate_consumed_transitively=true" \
  "stage824_commit_first_slice_owner_review_runtime_manager_consumed_transitively=true" \
  "shared_publication_runtime_manager_materialized=true" \
  "publication_runtime_contract_materialized=true" \
  "publication_execution_receipt_contract_materialized=true" \
  "cycle_order_publication_gate_rehearsal_demo_runtime_materialized=true" \
  "file_browser_publication_runtime_surface_materialized=true" \
  "publication_runtime_manager_bound_to_stage825_gate=true" \
  "publication_runtime_manager_bound_to_stage826_visibility_rehearsal=true" \
  "publication_runtime_manager_bound_to_stage827_demo_surface=true" \
  "future_per_demo_publication_template_need_reduced=true" \
  "stage829_component_state_store_publishable_state_model_after_stage828_prepared=true" \
  "new_public_surface_added=false" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage827_commit_first_slice_publication_demo_host_surface_suite_passed=true" \
  "file_browser_commit_first_slice_publication_preview_surface_materialized=true" \
  "commit_first_slice_publication_result_surface_materialized=true"; do
  require_file_fact "$STAGE827_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage825_commit_first_slice_publication_gate.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage826_commit_first_slice_publication_visibility_rehearsal.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage827_commit_first_slice_publication_demo_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage828_commit_first_slice_publication_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage828 commit first-slice publication runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage828 commit first-slice publication runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage828 commit first-slice publication runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(25|26|27|28)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage828 commit first-slice publication runtime manager suite: unexpected stage825-828 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage828 commit first-slice publication runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage828 commit first-slice publication runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage828 commit first-slice publication runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage828 commit first-slice publication runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage828_commit_first_slice_publication_runtime_manager_suite_version=1"
  echo "stage827_suite_packet=$STAGE827_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage825_stage828_public_declaration_scan_passed=true"
  echo "stage825_stage828_forbidden_native_render_token_scan_passed=true"
  echo "stage828_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage829_component_state_store_publishable_state_model_after_stage828"
  echo "stage828_commit_first_slice_publication_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage828 commit first-slice publication runtime manager suite: route_classification=commit_publication_runtime_manager"
echo "cjgui stage828 commit first-slice publication runtime manager suite: suite_packet_path=$SUITE_PACKET"
