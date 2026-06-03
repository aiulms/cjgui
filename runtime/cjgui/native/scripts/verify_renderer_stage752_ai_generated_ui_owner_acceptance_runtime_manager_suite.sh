#!/usr/bin/env zsh
#
# Focused suite for stage752. It consumes stage751, verifies the shared
# owner-acceptance runtime manager, builds runtime/cjgui, and scans stop-lines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE752_TMPDIR:-/private/tmp/cjgui-stage749-stage752/stage752}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage752-ai-generated-ui-owner-acceptance-runtime-manager-suite.packet"
STAGE751_SUITE_PACKET="${CJGUI_STAGE752_INPUT_PACKET:-${CJGUI_STAGE751_AI_GENERATED_UI_ACCEPTANCE_DEMO_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage749-stage752/stage751/stage751-ai-generated-ui-acceptance-demo-host-surface-suite.packet}}"
STAGE751_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage751_ai_generated_ui_acceptance_demo_host_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage752_ai_generated_ui_owner_acceptance_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage752-ai-generated-ui-owner-acceptance-runtime-manager-owner.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$BUILD_LOG"
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
    echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE751_SUITE_PACKET" ]] || ! grep -F "stage751_ai_generated_ui_acceptance_demo_host_surface_suite_passed=true" "$STAGE751_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE751_TMPDIR="$TMP_DIR/stage751" zsh "$STAGE751_SUITE_SCRIPT" >/dev/null
  STAGE751_SUITE_PACKET="$TMP_DIR/stage751/stage751-ai-generated-ui-acceptance-demo-host-surface-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage751_ai_generated_ui_acceptance_demo_host_surface_consumed=true" \
  "stage750_ai_generated_ui_public_surface_preflight_consumed_transitively=true" \
  "stage749_ai_generated_ui_owner_acceptance_preflight_consumed_transitively=true" \
  "stage748_ai_generated_ui_runtime_manager_consumed_transitively=true" \
  "shared_ai_generated_ui_owner_acceptance_runtime_manager_materialized=true" \
  "owner_acceptance_runtime_contract_materialized=true" \
  "owner_acceptance_execution_receipt_contract_materialized=true" \
  "cycle_order_ai_generated_owner_preflight_public_surface_host_runtime_materialized=true" \
  "future_per_demo_owner_acceptance_template_need_reduced=true" \
  "stage753_ai_generated_ui_acceptance_commit_preflight_prepared=true" \
  "owner_acceptance_granted=false" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage751_ai_generated_ui_acceptance_demo_host_surface_suite_passed=true" \
  "acceptance_demo_host_inspection_rows_materialized=true" \
  "acceptance_result_surface_preview_materialized=true" \
  "acceptance_render_command_preview_receipt_materialized=true" \
  "stage752_ai_generated_ui_owner_acceptance_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE751_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage749_ai_generated_ui_owner_acceptance_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage750_ai_generated_ui_public_surface_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage751_ai_generated_ui_acceptance_demo_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage752_ai_generated_ui_owner_acceptance_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_suite_version=1"
  echo "stage751_ai_generated_ui_acceptance_demo_host_surface_suite_packet=$STAGE751_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage749_stage752_public_foreign_scan_passed=true"
  echo "stage749_stage752_forbidden_native_render_token_scan_passed=true"
  echo "stage752_protected_path_scan_passed=true"
  echo "next_route=stage753_ai_generated_ui_acceptance_commit_preflight_after_stage752"
  echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: route_classification=owner_acceptance_runtime_manager_ready"
echo "cjgui stage752 ai generated ui owner acceptance runtime manager suite: suite_packet_path=$SUITE_PACKET"
