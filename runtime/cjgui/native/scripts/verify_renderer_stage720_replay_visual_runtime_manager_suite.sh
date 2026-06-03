#!/usr/bin/env zsh
#
# Focused suite for stage720. It consumes stage719, verifies the shared visual
# runtime manager, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE720_TMPDIR:-/private/tmp/cjgui-stage717-stage720/stage720}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage720-replay-visual-runtime-manager-suite.packet"
STAGE719_SUITE_PACKET="${CJGUI_STAGE720_INPUT_PACKET:-${CJGUI_STAGE719_REPLAY_TEXT_CARET_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage717-stage720/stage719/stage719-replay-text-caret-host-surface-suite.packet}}"
STAGE719_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage719_replay_text_caret_host_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage720_replay_visual_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage720-replay-visual-runtime-manager-owner.log"

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
    echo "cjgui stage720 replay visual runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE719_SUITE_PACKET" ]]; then
  zsh "$STAGE719_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage719_replay_text_caret_host_surface_consumed=true" \
  "shared_replay_visual_runtime_manager_materialized=true" \
  "shared_replay_visual_runtime_contract_materialized=true" \
  "replay_visual_execution_receipt_contract_materialized=true" \
  "cycle_order_replay_action_state_render_visual_resolve_text_caret_host_materialized=true" \
  "future_per_demo_replay_visual_runtime_template_need_reduced=true" \
  "stage721_component_runtime_visual_state_store_preflight_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage719_replay_text_caret_host_surface_suite_version=1" \
  "shared_replay_text_caret_model_materialized=true" \
  "replay_demo_host_inspection_surface_materialized=true" \
  "stage720_replay_visual_runtime_manager_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE719_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage717_replay_visual_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage718_replay_style_focus_resolver.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage719_replay_text_caret_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage720_replay_visual_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage720 replay visual runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage720 replay visual runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage720 replay visual runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage720 replay visual runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage720 replay visual runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage720 replay visual runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage720 replay visual runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage720_replay_visual_runtime_manager_suite_version=1"
  echo "stage719_replay_text_caret_host_surface_suite_packet=$STAGE719_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage717_stage720_public_foreign_scan_passed=true"
  echo "stage717_stage720_forbidden_native_render_token_scan_passed=true"
  echo "stage720_protected_path_scan_passed=true"
  echo "next_route=stage721_component_runtime_visual_state_store_preflight_after_stage720"
  echo "stage720_replay_visual_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage720 replay visual runtime manager suite: route_classification=replay_visual_runtime_manager_ready"
echo "cjgui stage720 replay visual runtime manager suite: suite_packet_path=$SUITE_PACKET"
