#!/usr/bin/env zsh
#
# Focused suite for stage832. It consumes stage831, builds runtime/cjgui, and
# records the shared publishable state runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE832_TMPDIR:-/private/tmp/cjgui-stage829-stage832/stage832}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage832-component-state-store-publishable-runtime-manager-suite.packet"
STAGE831_SUITE_PACKET="${CJGUI_STAGE832_INPUT_PACKET:-${CJGUI_STAGE831_COMPONENT_STATE_STORE_COMMIT_CANDIDATE_ROLLBACK_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage829-stage832/stage831/stage831-component-state-store-commit-candidate-rollback-snapshot-suite.packet}}"
STAGE831_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage832_component_state_store_publishable_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage832-component-state-store-publishable-runtime-manager-owner.log"

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
    echo "cjgui stage832 component state-store publishable runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE831_SUITE_PACKET" ]] || ! grep -F "stage831_component_state_store_commit_candidate_rollback_snapshot_suite_passed=true" "$STAGE831_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE831_TMPDIR="$TMP_DIR/stage831" zsh "$STAGE831_SUITE_SCRIPT" >/dev/null
  STAGE831_SUITE_PACKET="$TMP_DIR/stage831/stage831-component-state-store-commit-candidate-rollback-snapshot-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage832_component_state_store_publishable_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage832_component_state_store_publishable_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage831_component_state_store_commit_candidate_rollback_snapshot_consumed=true" \
  "stage830_component_state_store_slot_value_model_consumed_transitively=true" \
  "stage829_component_state_store_publishable_state_model_consumed_transitively=true" \
  "stage828_commit_first_slice_publication_runtime_manager_consumed_transitively=true" \
  "shared_publishable_state_runtime_manager_materialized=true" \
  "publishable_state_runtime_contract_materialized=true" \
  "publishable_state_execution_receipt_contract_materialized=true" \
  "cycle_order_publishable_state_slot_commit_demo_runtime_materialized=true" \
  "todo_publishable_state_runtime_surface_materialized=true" \
  "settings_publishable_state_runtime_surface_materialized=true" \
  "ai_generated_settings_publishable_state_runtime_surface_materialized=true" \
  "chat_composer_publishable_state_runtime_surface_materialized=true" \
  "file_browser_publishable_state_runtime_surface_materialized=true" \
  "publishable_runtime_manager_bound_to_stage829_state_model=true" \
  "publishable_runtime_manager_bound_to_stage830_slot_value_model=true" \
  "publishable_runtime_manager_bound_to_stage831_commit_candidate=true" \
  "future_per_demo_state_model_template_need_reduced=true" \
  "stage833_publishable_state_layout_style_resolver_after_stage832_prepared=true" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage831_component_state_store_commit_candidate_rollback_snapshot_suite_passed=true" \
  "owner_local_commit_candidate_materialized=true" \
  "rollback_snapshot_materialized=true" \
  "stage832_component_state_store_publishable_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE831_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage829_component_state_store_publishable_state_model.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage830_component_state_store_slot_value_model.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage832_component_state_store_publishable_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage832 component state-store publishable runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage832 component state-store publishable runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage832 component state-store publishable runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage8(29|30|31|32)' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage832 component state-store publishable runtime manager suite: unexpected stage829-832 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage832 component state-store publishable runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage832 component state-store publishable runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage832 component state-store publishable runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage832 component state-store publishable runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage832_component_state_store_publishable_runtime_manager_suite_version=1"
  echo "stage831_suite_packet=$STAGE831_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage829_stage832_public_declaration_scan_passed=true"
  echo "stage829_stage832_forbidden_native_render_token_scan_passed=true"
  echo "stage832_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage833_publishable_state_layout_style_resolver_after_stage832"
  echo "stage832_component_state_store_publishable_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage832 component state-store publishable runtime manager suite: route_classification=publishable_state_runtime_manager"
echo "cjgui stage832 component state-store publishable runtime manager suite: suite_packet_path=$SUITE_PACKET"
