#!/usr/bin/env zsh
#
# Focused suite for stage700. It consumes stage699, verifies the shared
# timeline action-state-render executor, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE700_TMPDIR:-/private/tmp/cjgui-stage697-stage700/stage700}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage700-replay-host-text-input-timeline-action-state-render-executor-suite.packet"
STAGE699_SUITE_PACKET="${CJGUI_STAGE700_INPUT_PACKET:-${CJGUI_STAGE699_REPLAY_HOST_TEXT_INPUT_TIMELINE_RENDER_RESULT_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage697-stage700/stage699/stage699-replay-host-text-input-timeline-render-result-refresh-suite.packet}}"
STAGE699_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage699_replay_host_text_input_timeline_render_result_refresh_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage700_replay_host_text_input_timeline_action_state_render_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage700-replay-host-text-input-timeline-action-state-render-executor-owner.log"

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
    echo "cjgui stage700 replay host text input timeline action-state-render executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE699_SUITE_PACKET" ]]; then
  zsh "$STAGE699_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage699_replay_host_text_input_timeline_render_result_refresh_consumed=true" \
  "shared_replay_host_text_input_timeline_action_state_render_executor_materialized=true" \
  "shared_replay_host_text_input_timeline_action_state_render_runtime_contract_materialized=true" \
  "timeline_action_state_render_execution_receipt_contract_materialized=true" \
  "cycle_order_text_input_timeline_action_intent_state_delta_render_result_executor_materialized=true" \
  "future_per_demo_text_input_timeline_action_state_render_template_need_reduced=true" \
  "stage701_text_input_timeline_component_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage699_replay_host_text_input_timeline_render_result_refresh_suite_version=1" \
  "shared_replay_host_text_input_timeline_render_result_refresh_bridge_materialized=true" \
  "chat_composer_replay_host_text_input_timeline_render_result_surface_materialized=true" \
  "stage700_replay_host_text_input_timeline_action_state_render_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE699_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage697_replay_host_text_input_timeline_action_intent_bridge.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage698_replay_host_text_input_timeline_state_delta_dry_run.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage699_replay_host_text_input_timeline_render_result_refresh.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage700_replay_host_text_input_timeline_action_state_render_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage700 replay host text input timeline action-state-render executor suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage700 replay host text input timeline action-state-render executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage700 replay host text input timeline action-state-render executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage700 replay host text input timeline action-state-render executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage700 replay host text input timeline action-state-render executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage700 replay host text input timeline action-state-render executor suite: runtime package build failed" >&2
  echo "cjgui stage700 replay host text input timeline action-state-render executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage700_replay_host_text_input_timeline_action_state_render_executor_suite_version=1"
  echo "stage699_replay_host_text_input_timeline_render_result_refresh_suite_packet=$STAGE699_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage697_stage700_public_foreign_scan_passed=true"
  echo "stage697_stage700_forbidden_native_render_token_scan_passed=true"
  echo "stage700_protected_path_scan_passed=true"
  echo "next_route=stage701_text_input_timeline_component_runtime_contract_after_stage700"
  echo "stage700_replay_host_text_input_timeline_action_state_render_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage700 replay host text input timeline action-state-render executor suite: route_classification=timeline_action_state_render_executor_ready"
echo "cjgui stage700 replay host text input timeline action-state-render executor suite: suite_packet_path=$SUITE_PACKET"
