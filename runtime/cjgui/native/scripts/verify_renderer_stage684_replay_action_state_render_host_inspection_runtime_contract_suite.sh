#!/usr/bin/env zsh
#
# Focused suite for stage684. It consumes stage683, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE684_TMPDIR:-/private/tmp/cjgui-stage681-stage684/stage684}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage684-replay-action-state-render-host-inspection-runtime-contract-suite.packet"
STAGE683_SUITE_PACKET="${CJGUI_STAGE684_INPUT_PACKET:-${CJGUI_STAGE683_REPLAY_ACTION_STATE_RENDER_HOST_RESULT_SURFACE_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage681-stage684/stage683/stage683-replay-action-state-render-host-result-surface-refresh-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage684-replay-action-state-render-host-inspection-runtime-contract-owner.log"

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
    echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage683_replay_action_state_render_host_result_surface_refresh_consumed=true" \
  "shared_replay_action_state_render_host_inspection_runtime_contract_materialized=true" \
  "shared_replay_action_state_render_host_inspection_runtime_helper_materialized=true" \
  "cycle_order_replay_action_state_render_host_inspection_layout_result_runtime_materialized=true" \
  "future_per_demo_replay_host_inspection_template_need_reduced=true" \
  "stage685_replay_action_state_render_host_input_feedback_loop_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage683_replay_action_state_render_host_result_surface_refresh_suite_version=1" \
  "shared_replay_host_result_surface_refresh_materialized=true" \
  "stage684_replay_action_state_render_host_inspection_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE683_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage681_replay_action_state_render_demo_host_inspection.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage683_replay_action_state_render_host_result_surface_refresh.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: runtime package build failed" >&2
  echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage684_replay_action_state_render_host_inspection_runtime_contract_suite_version=1"
  echo "stage683_replay_action_state_render_host_result_surface_refresh_suite_packet=$STAGE683_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage681_stage684_public_foreign_scan_passed=true"
  echo "stage681_stage684_forbidden_native_render_token_scan_passed=true"
  echo "stage684_protected_path_scan_passed=true"
  echo "next_route=stage685_replay_action_state_render_host_input_feedback_loop_after_stage684"
  echo "stage684_replay_action_state_render_host_inspection_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: route_classification=host_inspection_runtime_contract_ready"
echo "cjgui stage684 replay action-state-render host inspection runtime contract suite: suite_packet_path=$SUITE_PACKET"
