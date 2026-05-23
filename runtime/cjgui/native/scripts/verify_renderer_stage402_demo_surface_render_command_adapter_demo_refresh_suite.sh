#!/usr/bin/env zsh
#
# 维护注释：stage402 focused suite 消费 stage401 RenderCommand adapter packet，
# 验证 adapter slots 能形成 demo refresh command batch preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE402_TMPDIR:-/tmp/cjgui-stage402-demo-surface-render-command-adapter-demo-refresh-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage402-demo-surface-render-command-adapter-demo-refresh-suite.packet"
STAGE401_SUITE_PACKET="${CJGUI_STAGE402_INPUT_PACKET:-${CJGUI_STAGE401_DEMO_REFRESH_INPUT_PACKET:-${CJGUI_STAGE401_DEMO_SURFACE_EXECUTION_RESULT_RENDER_COMMAND_ADAPTER_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage402_demo_surface_render_command_adapter_demo_refresh_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage402_demo_surface_render_command_adapter_demo_refresh.cj"
OWNER_LOG="$TMP_DIR/stage402-demo-surface-render-command-adapter-demo-refresh-owner.log"

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
    echo "cjgui stage402 demo surface render command adapter demo refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage401_demo_surface_execution_result_render_command_adapter_consumed=true" \
  "render_command_adapter_slots_consumed=true" \
  "demo_surface_render_command_adapter_demo_refresh_materialized=true" \
  "todo_demo_surface_render_command_batch_refresh_materialized=true" \
  "settings_demo_surface_render_command_batch_refresh_materialized=true" \
  "ai_generated_settings_demo_surface_render_command_batch_refresh_materialized=true" \
  "demo_refresh_batch_bound_to_adapter_slots=true" \
  "demo_refresh_batch_bound_to_stage400_semantic_diff=true" \
  "demo_refresh_batch_bound_to_stage399_state_delta_preview=true" \
  "stage403_demo_surface_render_command_backend_adapter_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE401_SUITE_PACKET" || ! -f "$STAGE401_SUITE_PACKET" ]]; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: missing stage401 packet; set CJGUI_STAGE402_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage401_demo_surface_execution_result_render_command_adapter_suite_version=1" \
  "stage400_demo_surface_execution_semantic_refresh_consumed=true" \
  "stage399_demo_surface_event_execution_dry_run_consumed_transitively=true" \
  "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true" \
  "stage397_shared_component_event_binding_matrix_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "demo_surface_execution_result_consumed=true" \
  "demo_surface_execution_semantic_diff_consumed=true" \
  "demo_surface_execution_render_command_refresh_consumed=true" \
  "demo_surface_execution_result_render_command_adapter_materialized=true" \
  "todo_execution_result_to_render_command_slot_mapped=true" \
  "settings_execution_result_to_render_command_slot_mapped=true" \
  "ai_generated_settings_execution_result_to_render_command_slot_mapped=true" \
  "render_command_adapter_slots_owner_local=true" \
  "render_command_adapter_slots_preview_only=true" \
  "adapter_bound_to_stage398_render_command_plan=true" \
  "adapter_bound_to_stage399_state_delta_preview=true" \
  "adapter_bound_to_stage400_semantic_diff=true" \
  "stage402_demo_surface_render_command_adapter_demo_refresh_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE401_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: runtime package build failed" >&2
  echo "cjgui stage402 demo surface render command adapter demo refresh suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage401_next_route="$(fact_value "$STAGE401_SUITE_PACKET" "next_route")"

{
  echo "stage402_demo_surface_render_command_adapter_demo_refresh_suite_version=1"
  echo "stage401_demo_surface_execution_result_render_command_adapter_suite_packet=$STAGE401_SUITE_PACKET"
  echo "stage401_next_route=$stage401_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage402_demo_surface_render_command_adapter_demo_refresh_owner_passed=true"
  echo "stage401_demo_surface_execution_result_render_command_adapter_consumed=true"
  echo "stage400_demo_surface_execution_semantic_refresh_consumed_transitively=true"
  echo "stage399_demo_surface_event_execution_dry_run_consumed_transitively=true"
  echo "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "render_command_adapter_slots_consumed=true"
  echo "demo_surface_render_command_adapter_demo_refresh_materialized=true"
  echo "todo_demo_surface_render_command_batch_refresh_materialized=true"
  echo "settings_demo_surface_render_command_batch_refresh_materialized=true"
  echo "ai_generated_settings_demo_surface_render_command_batch_refresh_materialized=true"
  echo "demo_refresh_batch_bound_to_adapter_slots=true"
  echo "demo_refresh_batch_bound_to_stage400_semantic_diff=true"
  echo "demo_refresh_batch_bound_to_stage399_state_delta_preview=true"
  echo "demo_surface_render_command_batch_owner_local=true"
  echo "demo_surface_render_command_batch_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage402_public_foreign_scan_passed=true"
  echo "stage402_forbidden_native_render_token_scan_passed=true"
  echo "stage402_protected_path_scan_passed=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "demo_surface_render_command_adapter_demo_refresh_dry_run=true"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
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
  echo "stage403_demo_surface_render_command_backend_adapter_dry_run_prepared=true"
  echo "next_route=stage403_demo_surface_render_command_backend_adapter_dry_run_after_stage402"
  echo "stage402_demo_surface_render_command_adapter_demo_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage402 demo surface render command adapter demo refresh suite: route_classification=demo_refresh_command_batch_ready"
echo "cjgui stage402 demo surface render command adapter demo refresh suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage402 demo surface render command adapter demo refresh suite: consumed_stage401=true"
echo "cjgui stage402 demo surface render command adapter demo refresh suite: renderer_state_write=false"
