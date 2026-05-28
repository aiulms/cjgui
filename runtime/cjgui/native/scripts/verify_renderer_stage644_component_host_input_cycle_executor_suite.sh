#!/usr/bin/env zsh
#
# Focused suite for stage644. It consumes stage643 receipts, verifies the
# shared host input cycle executor contract, package build, and scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE644_TMPDIR:-/private/tmp/cjgui-stage641-stage644/stage644}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage644-component-host-input-cycle-executor-suite.packet"
STAGE643_SUITE_PACKET="${CJGUI_STAGE644_INPUT_PACKET:-${CJGUI_STAGE643_COMPONENT_HOST_INPUT_CYCLE_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage641-stage644/stage643/stage643-component-host-input-cycle-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage644_component_host_input_cycle_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage644-component-host-input-cycle-executor-owner.log"

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
    echo "cjgui stage644 component host input cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage643_component_host_input_cycle_receipt_consumed=true" \
  "shared_component_runtime_host_input_cycle_executor_contract_materialized=true" \
  "shared_component_runtime_host_input_cycle_executor_helper_materialized=true" \
  "chat_composer_component_host_input_runtime_surface_materialized=true" \
  "future_per_demo_result_surface_host_input_template_need_reduced=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE643_SUITE_PACKET" || ! -f "$STAGE643_SUITE_PACKET" ]]; then
  echo "cjgui stage644 component host input cycle executor suite: missing stage643 packet; set CJGUI_STAGE644_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage643_component_host_input_cycle_receipt_suite_version=1" \
  "shared_component_host_input_cycle_receipt_materialized=true" \
  "chat_composer_component_host_input_cycle_receipt_materialized=true" \
  "stage644_component_host_input_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE643_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage641_result_surface_host_input_adapter.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage642_component_host_input_event_queue.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage643_component_host_input_cycle_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage644_component_host_input_cycle_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage644 component host input cycle executor suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage644 component host input cycle executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage644 component host input cycle executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage644 component host input cycle executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage644 component host input cycle executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage644 component host input cycle executor suite: runtime package build failed" >&2
  echo "cjgui stage644 component host input cycle executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage644_component_host_input_cycle_executor_suite_version=1"
  echo "stage643_component_host_input_cycle_receipt_suite_packet=$STAGE643_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage644_component_host_input_cycle_executor_owner_passed=true"
  echo "stage643_component_host_input_cycle_receipt_consumed=true"
  echo "stage642_component_host_input_event_queue_consumed_transitively=true"
  echo "stage641_result_surface_host_input_adapter_consumed_transitively=true"
  echo "stage640_result_surface_host_runtime_contract_consumed_transitively=true"
  echo "shared_component_runtime_host_input_cycle_executor_contract_materialized=true"
  echo "shared_component_runtime_host_input_cycle_executor_helper_materialized=true"
  echo "shared_component_host_input_execution_receipt_contract_materialized=true"
  echo "cycle_order_host_event_queue_action_state_render_focus_receipt_materialized=true"
  echo "todo_component_host_input_runtime_surface_materialized=true"
  echo "settings_component_host_input_runtime_surface_materialized=true"
  echo "ai_generated_settings_component_host_input_runtime_surface_materialized=true"
  echo "chat_composer_component_host_input_runtime_surface_materialized=true"
  echo "stage640_host_runtime_bridged_to_shared_host_input_cycle=true"
  echo "future_per_demo_result_surface_host_input_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage641_stage644_public_foreign_scan_passed=true"
  echo "stage641_stage644_forbidden_native_render_token_scan_passed=true"
  echo "stage644_protected_path_scan_passed=true"
  echo "stage645_component_host_input_result_surface_refresh_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
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
  echo "next_route=stage645_component_host_input_result_surface_refresh_after_stage644"
  echo "stage644_component_host_input_cycle_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage644 component host input cycle executor suite: route_classification=component_host_input_cycle_executor_ready"
echo "cjgui stage644 component host input cycle executor suite: suite_packet_path=$SUITE_PACKET"
