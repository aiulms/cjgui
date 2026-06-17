#!/usr/bin/env zsh
#
# Focused suite for stage888. It consumes stage887, builds runtime/cjgui, and
# records the shared accepted commit publication runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE888_TMPDIR:-/private/tmp/cjgui-stage885-stage888/stage888}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage888-owner-local-accepted-commit-publication-runtime-manager-suite.packet"
STAGE887_SUITE_PACKET="${CJGUI_STAGE888_INPUT_PACKET:-${CJGUI_STAGE887_OWNER_LOCAL_ACCEPTED_COMMIT_PUBLICATION_DEMO_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage885-stage888/stage887/stage887-owner-local-accepted-commit-publication-demo-surface-suite.packet}}"
STAGE887_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage887_owner_local_accepted_commit_publication_demo_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage888_owner_local_accepted_commit_publication_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage888-owner-local-accepted-commit-publication-runtime-manager-owner.log"

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
    echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE887_SUITE_PACKET" ]] || ! grep -F "stage887_owner_local_accepted_commit_publication_demo_surface_suite_passed=true" "$STAGE887_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE887_TMPDIR="$TMP_DIR/stage887" zsh "$STAGE887_SUITE_SCRIPT" >/dev/null
  STAGE887_SUITE_PACKET="$TMP_DIR/stage887/stage887-owner-local-accepted-commit-publication-demo-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage885_owner_local_accepted_commit_publication_preflight_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage885_owner_local_accepted_commit_publication_preflight_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage886_owner_local_accepted_commit_publication_boundary_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage886_owner_local_accepted_commit_publication_boundary_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage887_owner_local_accepted_commit_publication_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage887_owner_local_accepted_commit_publication_demo_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage888_owner_local_accepted_commit_publication_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage888_owner_local_accepted_commit_publication_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage887_owner_local_accepted_commit_publication_demo_surface_suite_passed=true" \
  "file_browser_accepted_commit_publication_inspection_surface_materialized=true" \
  "accepted_commit_publication_surface_bound_to_boundary=true" \
  "stage888_owner_local_accepted_commit_publication_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE887_SUITE_PACKET" "$fact"
done

for fact in \
  "stage887_owner_local_accepted_commit_publication_demo_surface_consumed=true" \
  "stage886_owner_local_accepted_commit_publication_boundary_consumed_transitively=true" \
  "stage885_owner_local_accepted_commit_publication_preflight_consumed_transitively=true" \
  "stage884_owner_local_accepted_commit_runtime_manager_consumed_transitively=true" \
  "shared_owner_local_accepted_commit_publication_runtime_manager_materialized=true" \
  "owner_local_accepted_commit_publication_runtime_contract_materialized=true" \
  "owner_local_accepted_commit_publication_execution_receipt_contract_materialized=true" \
  "cycle_order_accepted_commit_publication_preflight_boundary_demo_runtime_materialized=true" \
  "file_browser_accepted_commit_publication_runtime_surface_materialized=true" \
  "common_owner_local_accepted_commit_publication_executor_materialized=true" \
  "accepted_commit_publication_inspection_runtime_bridge_materialized=true" \
  "future_per_demo_accepted_commit_publication_template_need_reduced=true" \
  "stage889_minimal_public_component_commit_api_readiness_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "state_store_write_executed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage885_owner_local_accepted_commit_publication_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage886_owner_local_accepted_commit_publication_boundary.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage887_owner_local_accepted_commit_publication_demo_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage888_owner_local_accepted_commit_publication_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalQueueSubmitShellReady"
if grep -E 'runtime_renderer_stage88(5|6|7|8).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: unexpected stage885-888 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage888_owner_local_accepted_commit_publication_runtime_manager_suite_version=1"
  echo "stage887_suite_packet=$STAGE887_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage885_stage888_public_declaration_scan_passed=true"
  echo "stage885_stage888_forbidden_native_render_token_scan_passed=true"
  echo "stage888_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage889_minimal_public_component_commit_api_readiness_after_stage888"
  echo "stage888_owner_local_accepted_commit_publication_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: route_classification=accepted_commit_publication_runtime_manager"
echo "cjgui stage888 owner-local accepted commit publication runtime manager suite: suite_packet_path=$SUITE_PACKET"
