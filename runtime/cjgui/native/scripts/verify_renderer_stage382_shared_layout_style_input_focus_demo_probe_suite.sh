#!/usr/bin/env zsh
#
# 维护注释：stage382 focused suite 消费 stage381 shared component model packet，
# 验证 shared layout/style/text/input/focus 已被 AI-generated settings / Todo demo surface dry-run 实际消费。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE382_TMPDIR:-/tmp/cjgui-stage382-shared-layout-style-input-focus-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage382-shared-layout-style-input-focus-demo-probe-suite.packet"
STAGE381_SUITE_PACKET="${CJGUI_STAGE381_SHARED_LAYOUT_STYLE_INPUT_FOCUS_INPUT_PACKET:-${CJGUI_STAGE381_SHARED_COMPONENT_MODEL_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage382_shared_layout_style_input_focus_demo_probe.cj"
OWNER_LOG="$TMP_DIR/stage382-shared-layout-style-input-focus-demo-probe-owner.log"

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
    echo "cjgui stage382 shared layout/style/input/focus demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage382_shared_model_consumed_by_demo_surface=true" \
  "ai_generated_settings_demo_consumed_shared_component_model=true" \
  "todo_demo_surface_consumed_shared_component_model=true" \
  "demo_layout_slots_materialized=true" \
  "demo_style_tokens_materialized=true" \
  "demo_text_runs_materialized=true" \
  "demo_input_bindings_materialized=true" \
  "demo_focus_traversal_materialized=true" \
  "owner_local_state_delta_from_demo_input_materialized=true" \
  "render_command_refresh_plan_from_demo_surface_materialized=true" \
  "owner_local_preview_only=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE381_SUITE_PACKET" || ! -f "$STAGE381_SUITE_PACKET" ]]; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: missing stage381 packet; set CJGUI_STAGE381_SHARED_LAYOUT_STYLE_INPUT_FOCUS_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage381_shared_component_model_suite_version=1" \
  "convergence_exit_decision_materialized=true" \
  "same_shape_surface_probe_readiness_loop_exited=true" \
  "shared_semantic_component_model_materialized=true" \
  "shared_layout_model_materialized=true" \
  "shared_style_model_materialized=true" \
  "shared_text_model_materialized=true" \
  "shared_input_model_materialized=true" \
  "shared_focus_model_materialized=true" \
  "shared_owner_local_state_delta_model_materialized=true" \
  "shared_render_command_refresh_plan_materialized=true" \
  "shared_component_model_bound_to_ai_generated_ui_demo=true" \
  "stage382_shared_layout_style_input_focus_demo_probe_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE381_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: runtime package build failed" >&2
  echo "cjgui stage382 shared layout/style/input/focus demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage381_next_route="$(fact_value "$STAGE381_SUITE_PACKET" "next_route")"

{
  echo "stage382_shared_layout_style_input_focus_demo_probe_suite_version=1"
  echo "stage381_shared_component_model_suite_packet=$STAGE381_SUITE_PACKET"
  echo "stage381_next_route=$stage381_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage382_shared_layout_style_input_focus_demo_probe_owner_passed=true"
  echo "stage381_shared_component_model_consumed=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "stage382_shared_model_consumed_by_demo_surface=true"
  echo "ai_generated_settings_demo_consumed_shared_component_model=true"
  echo "todo_demo_surface_consumed_shared_component_model=true"
  echo "shared_layout_model_consumed_by_demo_surface=true"
  echo "shared_style_model_consumed_by_demo_surface=true"
  echo "shared_text_model_consumed_by_demo_surface=true"
  echo "shared_input_model_consumed_by_demo_surface=true"
  echo "shared_focus_model_consumed_by_demo_surface=true"
  echo "demo_layout_slots_materialized=true"
  echo "demo_style_tokens_materialized=true"
  echo "demo_text_runs_materialized=true"
  echo "demo_input_bindings_materialized=true"
  echo "demo_focus_traversal_materialized=true"
  echo "owner_local_state_delta_from_demo_input_materialized=true"
  echo "render_command_refresh_plan_from_demo_surface_materialized=true"
  echo "ai_generated_ui_demo_surface_refresh_preview_materialized=true"
  echo "todo_demo_owner_local_preview_materialized=true"
  echo "runtime_package_build_passed=true"
  echo "stage382_public_foreign_scan_passed=true"
  echo "stage382_forbidden_native_render_token_scan_passed=true"
  echo "stage382_protected_path_scan_passed=true"
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
  echo "stage383_shared_action_state_render_bridge_demo_probe_prepared=true"
  echo "next_route=stage383_shared_action_state_render_bridge_demo_probe_after_stage382"
  echo "stage382_shared_layout_style_input_focus_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage382 shared layout/style/input/focus demo probe suite: route_classification=shared_model_demo_surface_consumption_ready"
echo "cjgui stage382 shared layout/style/input/focus demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage382 shared layout/style/input/focus demo probe suite: ai_generated_settings_and_todo_demo_surface=true"
echo "cjgui stage382 shared layout/style/input/focus demo probe suite: renderer_state_write=false"
