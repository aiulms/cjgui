#!/usr/bin/env zsh
#
# 维护注释：stage395 focused suite 消费 stage394 shared activation executor demo refresh helper packet，
# 验证 shared executor 进入 internal component-level activation contract。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE395_TMPDIR:-/tmp/cjgui-stage395-shared-activation-executor-component-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage395-shared-activation-executor-component-probe-suite.packet"
STAGE394_SUITE_PACKET="${CJGUI_STAGE395_INPUT_PACKET:-${CJGUI_STAGE394_SHARED_ACTIVATION_EXECUTOR_COMPONENT_INPUT_PACKET:-${CJGUI_STAGE394_SHARED_ACTIVATION_EXECUTOR_DEMO_REFRESH_HELPER_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage395_shared_activation_executor_component_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage395_shared_activation_executor_component_probe.cj"
OWNER_LOG="$TMP_DIR/stage395-shared-activation-executor-component-probe-owner.log"

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
    echo "cjgui stage395 shared activation executor component probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage395 shared activation executor component probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage395 shared activation executor component probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage395 shared activation executor component probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage395 shared activation executor component probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage394_shared_activation_executor_demo_refresh_helper_consumed=true" \
  "shared_executor_bound_to_component_identity=true" \
  "todo_add_component_activation_slot_materialized=true" \
  "settings_toggle_component_activation_slot_materialized=true" \
  "ai_generated_settings_component_activation_slot_materialized=true" \
  "component_activation_slots_bound_to_shared_component_model=true" \
  "component_activation_slots_bound_to_stage394_demo_refresh_helper=true" \
  "component_owner_acceptance_gate_materialized=true" \
  "component_state_delta_preview_materialized=true" \
  "component_render_refresh_binding_materialized=true" \
  "component_activation_probe_owner_local=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE394_SUITE_PACKET" || ! -f "$STAGE394_SUITE_PACKET" ]]; then
  echo "cjgui stage395 shared activation executor component probe suite: missing stage394 packet; set CJGUI_STAGE395_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage394_shared_activation_executor_demo_refresh_helper_suite_version=1" \
  "stage393_shared_activation_executor_helper_consumed=true" \
  "stage392_keyboard_activation_result_render_refresh_demo_probe_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "shared_executor_bound_to_todo_demo_activation_surface=true" \
  "shared_executor_bound_to_settings_demo_activation_surface=true" \
  "shared_executor_bound_to_ai_generated_settings_demo_surface=true" \
  "executor_driven_todo_state_delta_refresh_materialized=true" \
  "executor_driven_settings_state_delta_refresh_materialized=true" \
  "executor_driven_ai_generated_settings_refresh_materialized=true" \
  "shared_activation_demo_render_refresh_helper_materialized=true" \
  "demo_refresh_helper_bound_to_stage392_result_refresh=true" \
  "demo_refresh_helper_bound_to_stage383_render_bridge=true" \
  "shared_activation_executor_demo_refresh_preview_only=true" \
  "stage395_shared_activation_executor_component_probe_prepared=true" \
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
  require_file_fact "$STAGE394_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage395 shared activation executor component probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage395 shared activation executor component probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage395 shared activation executor component probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage395 shared activation executor component probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage395 shared activation executor component probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage395 shared activation executor component probe suite: runtime package build failed" >&2
  echo "cjgui stage395 shared activation executor component probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage394_next_route="$(fact_value "$STAGE394_SUITE_PACKET" "next_route")"

{
  echo "stage395_shared_activation_executor_component_probe_suite_version=1"
  echo "stage394_shared_activation_executor_demo_refresh_helper_suite_packet=$STAGE394_SUITE_PACKET"
  echo "stage394_next_route=$stage394_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage395_shared_activation_executor_component_probe_owner_passed=true"
  echo "stage394_shared_activation_executor_demo_refresh_helper_consumed=true"
  echo "stage393_shared_activation_executor_helper_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_executor_bound_to_component_identity=true"
  echo "todo_add_component_activation_slot_materialized=true"
  echo "settings_toggle_component_activation_slot_materialized=true"
  echo "ai_generated_settings_component_activation_slot_materialized=true"
  echo "component_activation_slots_bound_to_shared_component_model=true"
  echo "component_activation_slots_bound_to_stage394_demo_refresh_helper=true"
  echo "component_owner_acceptance_gate_materialized=true"
  echo "component_state_delta_preview_materialized=true"
  echo "component_render_refresh_binding_materialized=true"
  echo "component_activation_probe_owner_local=true"
  echo "component_activation_probe_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage395_public_foreign_scan_passed=true"
  echo "stage395_forbidden_native_render_token_scan_passed=true"
  echo "stage395_protected_path_scan_passed=true"
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
  echo "component_activation_probe_dry_run=true"
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
  echo "stage396_component_activation_render_refresh_probe_prepared=true"
  echo "next_route=stage396_component_activation_render_refresh_probe_after_stage395"
  echo "stage395_shared_activation_executor_component_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage395 shared activation executor component probe suite: route_classification=component_activation_probe_ready"
echo "cjgui stage395 shared activation executor component probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage395 shared activation executor component probe suite: consumed_stage394=true"
echo "cjgui stage395 shared activation executor component probe suite: renderer_state_write=false"
