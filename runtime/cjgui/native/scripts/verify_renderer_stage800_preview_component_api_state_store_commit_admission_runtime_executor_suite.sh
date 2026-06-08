#!/usr/bin/env zsh
#
# Focused suite for stage800. It consumes stage799, builds runtime/cjgui, and
# records the shared state-store commit admission runtime executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE800_TMPDIR:-/private/tmp/cjgui-stage797-stage800/stage800}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage800-preview-component-api-state-store-commit-admission-runtime-executor-suite.packet"
STAGE799_SUITE_PACKET="${CJGUI_STAGE800_INPUT_PACKET:-${CJGUI_STAGE799_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_DEMO_HOST_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage797-stage800/stage799/stage799-preview-component-api-state-store-commit-demo-host-preview-suite.packet}}"
STAGE799_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage799_preview_component_api_state_store_commit_demo_host_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage800_preview_component_api_state_store_commit_admission_runtime_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage800-preview-component-api-state-store-commit-admission-runtime-executor-owner.log"

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
    echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE799_SUITE_PACKET" ]] || ! grep -F "stage799_preview_component_api_state_store_commit_demo_host_preview_suite_passed=true" "$STAGE799_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE799_TMPDIR="$TMP_DIR/stage799" zsh "$STAGE799_SUITE_SCRIPT" >/dev/null
  STAGE799_SUITE_PACKET="$TMP_DIR/stage799/stage799-preview-component-api-state-store-commit-demo-host-preview-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage799_preview_component_api_state_store_commit_demo_host_preview_consumed=true" \
  "stage798_preview_component_api_state_store_commit_review_checkpoint_consumed_transitively=true" \
  "stage797_preview_component_api_state_store_commit_admission_preview_consumed_transitively=true" \
  "stage796_preview_component_api_state_store_bridge_runtime_manager_consumed_transitively=true" \
  "shared_state_store_commit_admission_runtime_executor_materialized=true" \
  "state_store_commit_admission_runtime_contract_materialized=true" \
  "state_store_commit_admission_execution_receipt_contract_materialized=true" \
  "cycle_order_admission_preview_review_demo_runtime_materialized=true" \
  "file_browser_commit_admission_runtime_surface_materialized=true" \
  "state_store_commit_admission_runtime_executor_bound_to_stage797_preview=true" \
  "state_store_commit_admission_runtime_executor_bound_to_stage798_checkpoint=true" \
  "state_store_commit_admission_runtime_executor_bound_to_stage799_demo_host_preview=true" \
  "future_per_demo_commit_admission_template_need_reduced=true" \
  "stage801_preview_component_api_state_store_commit_admission_diff_explain_prepared=true" \
  "new_public_surface_added=false" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage799_preview_component_api_state_store_commit_demo_host_preview_suite_passed=true" \
  "file_browser_commit_admission_preview_surface_materialized=true" \
  "stage800_preview_component_api_state_store_commit_admission_runtime_executor_prepared=true"; do
  require_file_fact "$STAGE799_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage797_preview_component_api_state_store_commit_admission_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage798_preview_component_api_state_store_commit_review_checkpoint.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage799_preview_component_api_state_store_commit_demo_host_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage800_preview_component_api_state_store_commit_admission_runtime_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage79(7|8|9)|runtime_renderer_stage800' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: unexpected stage797-800 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: runtime package build failed" >&2
  echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_suite_version=1"
  echo "stage799_preview_component_api_state_store_commit_demo_host_preview_suite_packet=$STAGE799_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage797_stage800_public_declaration_scan_passed=true"
  echo "stage797_stage800_forbidden_native_render_token_scan_passed=true"
  echo "stage800_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage801_preview_component_api_state_store_commit_admission_diff_explain_after_stage800"
  echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: route_classification=state_store_commit_admission_runtime_executor"
echo "cjgui stage800 preview component api state-store commit admission runtime executor suite: suite_packet_path=$SUITE_PACKET"
