#!/usr/bin/env zsh
#
# Focused suite for stage676. It consumes stage675, verifies the shared replay
# runtime executor, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE676_TMPDIR:-/private/tmp/cjgui-stage673-stage676/stage676}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage676-feedback-input-replay-runtime-executor-suite.packet"
STAGE675_SUITE_PACKET="${CJGUI_STAGE676_INPUT_PACKET:-${CJGUI_STAGE675_FEEDBACK_INPUT_REPLAY_RESULT_SURFACE_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage673-stage676/stage675/stage675-feedback-input-replay-result-surface-refresh-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage676_feedback_input_replay_runtime_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage676-feedback-input-replay-runtime-executor-owner.log"

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
    echo "cjgui stage676 feedback input replay runtime executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage675_feedback_input_replay_result_surface_refresh_consumed=true" \
  "shared_feedback_input_replay_runtime_executor_materialized=true" \
  "shared_feedback_input_replay_runtime_contract_materialized=true" \
  "replay_execution_receipt_contract_materialized=true" \
  "cycle_order_event_cycle_runtime_replay_inspection_result_executor_materialized=true" \
  "future_per_demo_feedback_input_replay_template_need_reduced=true" \
  "stage677_feedback_input_replay_action_state_bridge_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE675_SUITE_PACKET" || ! -f "$STAGE675_SUITE_PACKET" ]]; then
  echo "cjgui stage676 feedback input replay runtime executor suite: missing stage675 packet; set CJGUI_STAGE676_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage675_feedback_input_replay_result_surface_refresh_suite_version=1" \
  "shared_replay_result_surface_refresh_receipt_materialized=true" \
  "chat_composer_feedback_input_replay_result_surface_refresh_materialized=true" \
  "stage676_feedback_input_replay_runtime_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE675_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage673_feedback_input_event_replay_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage674_feedback_input_replay_host_inspection_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage675_feedback_input_replay_result_surface_refresh.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage676_feedback_input_replay_runtime_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage676 feedback input replay runtime executor suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage676 feedback input replay runtime executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage676 feedback input replay runtime executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage676 feedback input replay runtime executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage676 feedback input replay runtime executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage676 feedback input replay runtime executor suite: runtime package build failed" >&2
  echo "cjgui stage676 feedback input replay runtime executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage676_feedback_input_replay_runtime_executor_suite_version=1"
  echo "stage675_feedback_input_replay_result_surface_refresh_suite_packet=$STAGE675_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage676_feedback_input_replay_runtime_executor_owner_passed=true"
  echo "stage675_feedback_input_replay_result_surface_refresh_consumed=true"
  echo "stage674_feedback_input_replay_host_inspection_preview_consumed_transitively=true"
  echo "stage673_feedback_input_event_replay_surface_consumed_transitively=true"
  echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed_transitively=true"
  echo "shared_feedback_input_replay_runtime_executor_materialized=true"
  echo "shared_feedback_input_replay_runtime_contract_materialized=true"
  echo "replay_execution_receipt_contract_materialized=true"
  echo "cycle_order_event_cycle_runtime_replay_inspection_result_executor_materialized=true"
  echo "todo_feedback_input_replay_runtime_surface_materialized=true"
  echo "settings_feedback_input_replay_runtime_surface_materialized=true"
  echo "ai_generated_settings_feedback_input_replay_runtime_surface_materialized=true"
  echo "chat_composer_feedback_input_replay_runtime_surface_materialized=true"
  echo "future_per_demo_feedback_input_replay_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage673_stage676_public_foreign_scan_passed=true"
  echo "stage673_stage676_forbidden_native_render_token_scan_passed=true"
  echo "stage676_protected_path_scan_passed=true"
  echo "stage677_feedback_input_replay_action_state_bridge_prepared=true"
  echo "host_mutation=false"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage677_feedback_input_replay_action_state_bridge_after_stage676"
  echo "stage676_feedback_input_replay_runtime_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage676 feedback input replay runtime executor suite: route_classification=feedback_input_replay_runtime_executor_ready"
echo "cjgui stage676 feedback input replay runtime executor suite: suite_packet_path=$SUITE_PACKET"
