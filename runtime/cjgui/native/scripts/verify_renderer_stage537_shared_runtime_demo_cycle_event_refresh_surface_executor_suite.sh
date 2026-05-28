#!/usr/bin/env zsh
#
# Focused suite for stage537. It consumes stage536 event RenderCommand refresh
# inputs and verifies a shared demo-surface refresh executor/receipt contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE537_TMPDIR:-/tmp/cjgui-stage537-shared-runtime-demo-cycle-event-refresh-surface-executor-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage537-shared-runtime-demo-cycle-event-refresh-surface-executor-suite.packet"
STAGE536_SUITE_PACKET="${CJGUI_STAGE537_INPUT_PACKET:-${CJGUI_STAGE536_SHARED_RUNTIME_DEMO_CYCLE_EVENT_RENDER_COMMAND_REFRESH_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage537_shared_runtime_demo_cycle_event_refresh_surface_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage537_shared_runtime_demo_cycle_event_refresh_surface_executor.cj"
OWNER_LOG="$TMP_DIR/stage537-shared-runtime-demo-cycle-event-refresh-surface-executor-owner.log"

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
    echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage536_shared_runtime_demo_cycle_event_render_command_refresh_consumed=true" \
  "shared_runtime_demo_cycle_event_refresh_surface_executor_materialized=true" \
  "shared_runtime_demo_cycle_event_refresh_execution_receipt_materialized=true" \
  "todo_event_refresh_surface_execution_receipt_materialized=true" \
  "settings_event_refresh_surface_execution_receipt_materialized=true" \
  "ai_generated_settings_event_refresh_surface_execution_receipt_materialized=true" \
  "event_refresh_surface_executor_bound_to_stage530_executor=true" \
  "event_refresh_surface_executor_bound_to_stage534_cycle_probe=true" \
  "event_refresh_surface_executor_bound_to_todo_settings_ai_generated_settings=true" \
  "event_state_render_layout_probe_order_materialized=true" \
  "event_refresh_surface_executor_reusable=true" \
  "event_state_render_owner_probe_duplication_reduced=true" \
  "stage538_shared_runtime_demo_cycle_event_refresh_host_probe_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE536_SUITE_PACKET" || ! -f "$STAGE536_SUITE_PACKET" ]]; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: missing stage536 packet; set CJGUI_STAGE537_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage536_shared_runtime_demo_cycle_event_render_command_refresh_suite_version=1" \
  "stage535_shared_runtime_demo_cycle_event_state_refresh_consumed=true" \
  "shared_runtime_demo_cycle_event_render_command_refresh_contract_materialized=true" \
  "normalized_event_state_to_render_command_refresh_bridge_materialized=true" \
  "todo_normalized_event_render_command_refresh_input_materialized=true" \
  "settings_normalized_event_render_command_refresh_input_materialized=true" \
  "ai_generated_settings_normalized_event_render_command_refresh_input_materialized=true" \
  "event_state_refresh_to_render_command_refresh_bound=true" \
  "event_render_command_refresh_bound_to_stage530_executor_route=true" \
  "event_render_command_refresh_preview_only=true" \
  "stage537_shared_runtime_demo_cycle_event_refresh_surface_executor_prepared=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE536_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: runtime package build failed" >&2
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage536_next_route="$(fact_value "$STAGE536_SUITE_PACKET" "next_route")"

{
  echo "stage537_shared_runtime_demo_cycle_event_refresh_surface_executor_suite_version=1"
  echo "stage536_shared_runtime_demo_cycle_event_render_command_refresh_suite_packet=$STAGE536_SUITE_PACKET"
  echo "stage536_next_route=$stage536_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage537_shared_runtime_demo_cycle_event_refresh_surface_executor_owner_passed=true"
  echo "stage536_shared_runtime_demo_cycle_event_render_command_refresh_consumed=true"
  echo "stage535_shared_runtime_demo_cycle_event_state_refresh_consumed_transitively=true"
  echo "stage534_normalized_event_demo_surface_cycle_probe_consumed_transitively=true"
  echo "normalized_event_render_command_refresh_inputs_consumed=true"
  echo "shared_runtime_demo_cycle_event_refresh_surface_executor_materialized=true"
  echo "shared_runtime_demo_cycle_event_refresh_execution_receipt_materialized=true"
  echo "todo_event_refresh_surface_execution_receipt_materialized=true"
  echo "settings_event_refresh_surface_execution_receipt_materialized=true"
  echo "ai_generated_settings_event_refresh_surface_execution_receipt_materialized=true"
  echo "event_refresh_surface_executor_bound_to_stage530_executor=true"
  echo "event_refresh_surface_executor_bound_to_stage534_cycle_probe=true"
  echo "event_refresh_surface_executor_bound_to_todo_settings_ai_generated_settings=true"
  echo "event_state_render_layout_probe_order_materialized=true"
  echo "event_refresh_surface_executor_reusable=true"
  echo "event_state_render_owner_probe_duplication_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage537_public_foreign_scan_passed=true"
  echo "stage537_forbidden_native_render_token_scan_passed=true"
  echo "stage537_protected_path_scan_passed=true"
  echo "stage538_shared_runtime_demo_cycle_event_refresh_host_probe_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "text_shaping_enabled=false"
  echo "focus_manager_enabled=false"
  echo "backend_implementation=false"
  echo "concrete_platform_capability_promise=false"
  echo "platform_command_buffer=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage538_shared_runtime_demo_cycle_event_refresh_host_probe_after_stage537"
  echo "stage537_shared_runtime_demo_cycle_event_refresh_surface_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: route_classification=event_refresh_surface_executor_ready"
echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: consumed_stage536=true"
echo "cjgui stage537 shared runtime demo cycle event refresh surface executor suite: renderer_submission=false"
