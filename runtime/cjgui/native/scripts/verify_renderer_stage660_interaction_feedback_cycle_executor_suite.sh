#!/usr/bin/env zsh
#
# Focused suite for stage660. It consumes stage659 result surfaces, verifies
# the shared interaction feedback cycle executor, builds the runtime package,
# and runs protected-path scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE660_TMPDIR:-/private/tmp/cjgui-stage657-stage660/stage660}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage660-interaction-feedback-cycle-executor-suite.packet"
STAGE659_SUITE_PACKET="${CJGUI_STAGE660_INPUT_PACKET:-${CJGUI_STAGE659_INTERACTION_FEEDBACK_RESULT_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage657-stage660/stage659/stage659-interaction-feedback-result-surface-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage660_interaction_feedback_cycle_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage660-interaction-feedback-cycle-executor-owner.log"

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
    echo "cjgui stage660 interaction feedback cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage659_interaction_feedback_result_surface_consumed=true" \
  "shared_interaction_feedback_cycle_executor_contract_materialized=true" \
  "shared_interaction_feedback_cycle_executor_helper_materialized=true" \
  "chat_composer_interaction_feedback_cycle_runtime_surface_materialized=true" \
  "future_per_demo_interaction_feedback_execution_template_need_reduced=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE659_SUITE_PACKET" || ! -f "$STAGE659_SUITE_PACKET" ]]; then
  echo "cjgui stage660 interaction feedback cycle executor suite: missing stage659 packet; set CJGUI_STAGE660_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage659_interaction_feedback_result_surface_suite_version=1" \
  "shared_interaction_feedback_result_surface_materialized=true" \
  "chat_composer_interaction_feedback_result_surface_materialized=true" \
  "stage660_interaction_feedback_cycle_executor_after_stage659_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE659_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage657_interaction_execution_feedback.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage658_interaction_feedback_reducer.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage659_interaction_feedback_result_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage660_interaction_feedback_cycle_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage660 interaction feedback cycle executor suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage660 interaction feedback cycle executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage660 interaction feedback cycle executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage660 interaction feedback cycle executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage660 interaction feedback cycle executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage660 interaction feedback cycle executor suite: runtime package build failed" >&2
  echo "cjgui stage660 interaction feedback cycle executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage660_interaction_feedback_cycle_executor_suite_version=1"
  echo "stage659_interaction_feedback_result_surface_suite_packet=$STAGE659_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage660_interaction_feedback_cycle_executor_owner_passed=true"
  echo "stage659_interaction_feedback_result_surface_consumed=true"
  echo "stage658_interaction_feedback_reducer_consumed_transitively=true"
  echo "stage657_interaction_execution_feedback_consumed_transitively=true"
  echo "stage656_interaction_feedback_host_runtime_contract_consumed_transitively=true"
  echo "shared_interaction_feedback_cycle_executor_contract_materialized=true"
  echo "shared_interaction_feedback_cycle_executor_helper_materialized=true"
  echo "shared_interaction_feedback_cycle_execution_receipt_contract_materialized=true"
  echo "cycle_order_host_runtime_execution_feedback_reducer_result_surface_materialized=true"
  echo "todo_interaction_feedback_cycle_runtime_surface_materialized=true"
  echo "settings_interaction_feedback_cycle_runtime_surface_materialized=true"
  echo "ai_generated_settings_interaction_feedback_cycle_runtime_surface_materialized=true"
  echo "chat_composer_interaction_feedback_cycle_runtime_surface_materialized=true"
  echo "future_per_demo_interaction_feedback_execution_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage657_stage660_public_foreign_scan_passed=true"
  echo "stage657_stage660_forbidden_native_render_token_scan_passed=true"
  echo "stage660_protected_path_scan_passed=true"
  echo "stage661_component_host_input_result_surface_interaction_feedback_input_bridge_after_stage660_prepared=true"
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
  echo "next_route=stage661_component_host_input_result_surface_interaction_feedback_input_bridge_after_stage660"
  echo "stage660_interaction_feedback_cycle_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage660 interaction feedback cycle executor suite: route_classification=interaction_feedback_cycle_executor_ready"
echo "cjgui stage660 interaction feedback cycle executor suite: suite_packet_path=$SUITE_PACKET"
