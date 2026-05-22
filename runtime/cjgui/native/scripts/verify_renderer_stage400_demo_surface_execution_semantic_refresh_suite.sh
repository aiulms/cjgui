#!/usr/bin/env zsh
#
# 维护注释：stage400 focused suite 消费 stage399 demo surface execution packet，
# 验证 execution result 能形成 semantic diff 与 RenderCommand refresh preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE400_TMPDIR:-/tmp/cjgui-stage400-demo-surface-execution-semantic-refresh-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage400-demo-surface-execution-semantic-refresh-suite.packet"
STAGE399_SUITE_PACKET="${CJGUI_STAGE400_INPUT_PACKET:-${CJGUI_STAGE399_DEMO_SURFACE_EXECUTION_SEMANTIC_INPUT_PACKET:-${CJGUI_STAGE399_DEMO_SURFACE_EVENT_EXECUTION_DRY_RUN_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage400_demo_surface_execution_semantic_refresh_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage400_demo_surface_execution_semantic_refresh.cj"
OWNER_LOG="$TMP_DIR/stage400-demo-surface-execution-semantic-refresh-owner.log"

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
    echo "cjgui stage400 demo surface execution semantic refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage400 demo surface execution semantic refresh suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage399_demo_surface_event_execution_dry_run_consumed=true" \
  "demo_surface_execution_semantic_diff_materialized=true" \
  "todo_demo_surface_execution_semantic_diff_materialized=true" \
  "settings_demo_surface_execution_semantic_diff_materialized=true" \
  "ai_generated_settings_demo_surface_execution_semantic_diff_materialized=true" \
  "demo_surface_execution_render_command_refresh_materialized=true" \
  "execution_refresh_bound_to_stage398_component_event_sequence_render_command_plan=true" \
  "execution_refresh_bound_to_stage399_state_delta_preview=true" \
  "stage401_demo_surface_execution_result_to_render_command_adapter_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE399_SUITE_PACKET" || ! -f "$STAGE399_SUITE_PACKET" ]]; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: missing stage399 packet; set CJGUI_STAGE400_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage399_demo_surface_event_execution_dry_run_suite_version=1" \
  "stage398_component_event_sequence_render_refresh_probe_consumed=true" \
  "stage397_shared_component_event_binding_matrix_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "component_event_sequence_dry_run_consumed=true" \
  "demo_surface_event_execution_dry_run_materialized=true" \
  "todo_demo_surface_execution_result_materialized=true" \
  "settings_demo_surface_execution_result_materialized=true" \
  "ai_generated_settings_demo_surface_execution_result_materialized=true" \
  "demo_surface_execution_bound_to_component_event_sequence=true" \
  "demo_surface_execution_bound_to_owner_acceptance_gate=true" \
  "demo_surface_execution_state_delta_preview_materialized=true" \
  "demo_surface_execution_owner_local=true" \
  "demo_surface_execution_preview_only=true" \
  "stage400_demo_surface_execution_semantic_refresh_prepared=true" \
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
  require_file_fact "$STAGE399_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage400 demo surface execution semantic refresh suite: runtime package build failed" >&2
  echo "cjgui stage400 demo surface execution semantic refresh suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage399_next_route="$(fact_value "$STAGE399_SUITE_PACKET" "next_route")"

{
  echo "stage400_demo_surface_execution_semantic_refresh_suite_version=1"
  echo "stage399_demo_surface_event_execution_dry_run_suite_packet=$STAGE399_SUITE_PACKET"
  echo "stage399_next_route=$stage399_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage400_demo_surface_execution_semantic_refresh_owner_passed=true"
  echo "stage399_demo_surface_event_execution_dry_run_consumed=true"
  echo "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true"
  echo "stage397_shared_component_event_binding_matrix_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "demo_surface_execution_result_consumed=true"
  echo "demo_surface_execution_semantic_diff_materialized=true"
  echo "todo_demo_surface_execution_semantic_diff_materialized=true"
  echo "settings_demo_surface_execution_semantic_diff_materialized=true"
  echo "ai_generated_settings_demo_surface_execution_semantic_diff_materialized=true"
  echo "demo_surface_execution_render_command_refresh_materialized=true"
  echo "execution_refresh_bound_to_stage398_component_event_sequence_render_command_plan=true"
  echo "execution_refresh_bound_to_stage399_state_delta_preview=true"
  echo "demo_surface_execution_semantic_refresh_owner_local=true"
  echo "demo_surface_execution_semantic_refresh_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage400_public_foreign_scan_passed=true"
  echo "stage400_forbidden_native_render_token_scan_passed=true"
  echo "stage400_protected_path_scan_passed=true"
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
  echo "demo_surface_execution_semantic_refresh_dry_run=true"
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
  echo "stage401_demo_surface_execution_result_to_render_command_adapter_prepared=true"
  echo "next_route=stage401_demo_surface_execution_result_to_render_command_adapter_after_stage400"
  echo "stage400_demo_surface_execution_semantic_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage400 demo surface execution semantic refresh suite: route_classification=demo_surface_execution_semantic_refresh_ready"
echo "cjgui stage400 demo surface execution semantic refresh suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage400 demo surface execution semantic refresh suite: consumed_stage399=true"
echo "cjgui stage400 demo surface execution semantic refresh suite: renderer_state_write=false"
