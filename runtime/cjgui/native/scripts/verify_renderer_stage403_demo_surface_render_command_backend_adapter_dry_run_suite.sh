#!/usr/bin/env zsh
#
# 维护注释：stage403 focused suite 消费 stage402 demo refresh command batch packet，
# 验证 RenderCommand batch 能形成 backend adapter dry-run mapping。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE403_TMPDIR:-/tmp/cjgui-stage403-demo-surface-render-command-backend-adapter-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage403-demo-surface-render-command-backend-adapter-dry-run-suite.packet"
STAGE402_SUITE_PACKET="${CJGUI_STAGE403_INPUT_PACKET:-${CJGUI_STAGE402_DEMO_SURFACE_RENDER_COMMAND_ADAPTER_DEMO_REFRESH_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage403_demo_surface_render_command_backend_adapter_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage403_demo_surface_render_command_backend_adapter_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage403-demo-surface-render-command-backend-adapter-dry-run-owner.log"

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
    echo "cjgui stage403 demo surface render command backend adapter dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage402_demo_surface_render_command_adapter_demo_refresh_consumed=true" \
  "demo_surface_render_command_batch_consumed=true" \
  "backend_adapter_dry_run_mapping_materialized=true" \
  "todo_render_command_batch_to_backend_adapter_slot_mapped=true" \
  "settings_render_command_batch_to_backend_adapter_slot_mapped=true" \
  "ai_generated_settings_render_command_batch_to_backend_adapter_slot_mapped=true" \
  "backend_adapter_dry_run_bound_to_stage402_command_batch=true" \
  "backend_adapter_mapping_owner_local=true" \
  "backend_adapter_mapping_preview_only=true" \
  "stage404_demo_surface_backend_adapter_result_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE402_SUITE_PACKET" || ! -f "$STAGE402_SUITE_PACKET" ]]; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: missing stage402 packet; set CJGUI_STAGE403_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage402_demo_surface_render_command_adapter_demo_refresh_suite_version=1" \
  "stage401_demo_surface_execution_result_render_command_adapter_consumed=true" \
  "stage400_demo_surface_execution_semantic_refresh_consumed_transitively=true" \
  "stage399_demo_surface_event_execution_dry_run_consumed_transitively=true" \
  "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "render_command_adapter_slots_consumed=true" \
  "demo_surface_render_command_adapter_demo_refresh_materialized=true" \
  "todo_demo_surface_render_command_batch_refresh_materialized=true" \
  "settings_demo_surface_render_command_batch_refresh_materialized=true" \
  "ai_generated_settings_demo_surface_render_command_batch_refresh_materialized=true" \
  "demo_refresh_batch_bound_to_adapter_slots=true" \
  "demo_refresh_batch_bound_to_stage400_semantic_diff=true" \
  "demo_refresh_batch_bound_to_stage399_state_delta_preview=true" \
  "demo_surface_render_command_batch_owner_local=true" \
  "demo_surface_render_command_batch_preview_only=true" \
  "stage403_demo_surface_render_command_backend_adapter_dry_run_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "public_component_api_added=false" \
  "layout_engine_enabled=false" \
  "input_event_pipeline_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "backend_implementation=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE402_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: runtime package build failed" >&2
  echo "cjgui stage403 demo surface render command backend adapter dry-run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage402_next_route="$(fact_value "$STAGE402_SUITE_PACKET" "next_route")"

{
  echo "stage403_demo_surface_render_command_backend_adapter_dry_run_suite_version=1"
  echo "stage402_demo_surface_render_command_adapter_demo_refresh_suite_packet=$STAGE402_SUITE_PACKET"
  echo "stage402_next_route=$stage402_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage403_demo_surface_render_command_backend_adapter_dry_run_owner_passed=true"
  echo "stage402_demo_surface_render_command_adapter_demo_refresh_consumed=true"
  echo "stage401_demo_surface_execution_result_render_command_adapter_consumed_transitively=true"
  echo "stage400_demo_surface_execution_semantic_refresh_consumed_transitively=true"
  echo "stage399_demo_surface_event_execution_dry_run_consumed_transitively=true"
  echo "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "demo_surface_render_command_batch_consumed=true"
  echo "backend_adapter_dry_run_mapping_materialized=true"
  echo "todo_render_command_batch_to_backend_adapter_slot_mapped=true"
  echo "settings_render_command_batch_to_backend_adapter_slot_mapped=true"
  echo "ai_generated_settings_render_command_batch_to_backend_adapter_slot_mapped=true"
  echo "backend_adapter_dry_run_bound_to_stage402_command_batch=true"
  echo "backend_adapter_mapping_owner_local=true"
  echo "backend_adapter_mapping_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage403_public_foreign_scan_passed=true"
  echo "stage403_forbidden_native_render_token_scan_passed=true"
  echo "stage403_protected_path_scan_passed=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
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
  echo "stage404_demo_surface_backend_adapter_result_refresh_prepared=true"
  echo "next_route=stage404_demo_surface_backend_adapter_result_refresh_after_stage403"
  echo "stage403_demo_surface_render_command_backend_adapter_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage403 demo surface render command backend adapter dry-run suite: route_classification=backend_adapter_mapping_dry_run_ready"
echo "cjgui stage403 demo surface render command backend adapter dry-run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage403 demo surface render command backend adapter dry-run suite: consumed_stage402=true"
echo "cjgui stage403 demo surface render command backend adapter dry-run suite: renderer_state_write=false"
