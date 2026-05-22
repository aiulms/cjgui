#!/usr/bin/env zsh
#
# 维护注释：stage381 focused suite 消费 stage380 convergence loop packet，
# 并验证 shared component model 能把 AI-generated UI demo 接回 state/render dry-run 能力。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE381_TMPDIR:-/tmp/cjgui-stage381-shared-component-model-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage381-shared-component-model-suite.packet"
STAGE380_SUITE_PACKET="${CJGUI_STAGE380_SHARED_COMPONENT_MODEL_INPUT_PACKET:-${CJGUI_STAGE380_INTERNAL_AI_GENERATED_UI_DEMO_EXECUTION_FEEDBACK_LOOP_CONVERGENCE_LOOP_READINESS_DECISION_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage381_shared_component_model_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage381_shared_component_model.cj"
OWNER_LOG="$TMP_DIR/stage381-shared-component-model-owner.log"

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
    echo "cjgui stage381 shared component model suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage381 shared component model suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage381 shared component model suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage381 shared component model suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage381 shared component model suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
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
  "shared_component_model_bound_to_owner_local_state_delta=true" \
  "shared_component_model_bound_to_render_command_refresh=true" \
  "stage382_shared_layout_style_input_focus_demo_probe_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE380_SUITE_PACKET" || ! -f "$STAGE380_SUITE_PACKET" ]]; then
  echo "cjgui stage381 shared component model suite: missing stage380 packet; set CJGUI_STAGE380_SHARED_COMPONENT_MODEL_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage377_380_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_probe_to_surface_suite_version=1" \
  "internal_ai_generated_ui_demo_execution_feedback_loop_convergence_loop_readiness_decision_materialized=true" \
  "stage381_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_loop_surface_refresh_prepared=true" \
  "execution_feedback_loop_convergence_loop_runway_rollback_visibility_boundary_joined=true" \
  "minimal_ui_framework_ai_generated_ui_execution_feedback_loop_convergence_loop_runway_advanced=true" \
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
  require_file_fact "$STAGE380_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage381 shared component model suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage381 shared component model suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage381 shared component model suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage381 shared component model suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage381 shared component model suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage381 shared component model suite: runtime package build failed" >&2
  echo "cjgui stage381 shared component model suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage380_next_route="$(fact_value "$STAGE380_SUITE_PACKET" "next_route")"

{
  echo "stage381_shared_component_model_suite_version=1"
  echo "stage380_convergence_loop_readiness_decision_suite_packet=$STAGE380_SUITE_PACKET"
  echo "stage380_next_route=$stage380_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage381_shared_component_model_owner_passed=true"
  echo "stage380_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_loop_readiness_decision_consumed=true"
  echo "stage323_backend_result_state_render_bridge_consumed=true"
  echo "convergence_exit_decision_materialized=true"
  echo "same_shape_surface_probe_readiness_loop_exited=true"
  echo "shared_semantic_component_model_materialized=true"
  echo "shared_layout_model_materialized=true"
  echo "shared_style_model_materialized=true"
  echo "shared_text_model_materialized=true"
  echo "shared_input_model_materialized=true"
  echo "shared_focus_model_materialized=true"
  echo "shared_owner_local_state_delta_model_materialized=true"
  echo "shared_render_command_refresh_plan_materialized=true"
  echo "shared_component_model_bound_to_ai_generated_ui_demo=true"
  echo "shared_component_model_bound_to_owner_local_state_delta=true"
  echo "shared_component_model_bound_to_render_command_refresh=true"
  echo "ai_generated_ui_demo_consumed_shared_component_model=true"
  echo "todo_settings_chat_file_browser_reuse_path_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage381_public_foreign_scan_passed=true"
  echo "stage381_forbidden_native_render_token_scan_passed=true"
  echo "stage381_protected_path_scan_passed=true"
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
  echo "stage382_shared_layout_style_input_focus_demo_probe_prepared=true"
  echo "next_route=stage382_shared_layout_style_input_focus_demo_probe_after_shared_component_model"
  echo "stage381_shared_component_model_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage381 shared component model suite: route_classification=convergence_exit_to_shared_component_model_ready"
echo "cjgui stage381 shared component model suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage381 shared component model suite: shared_component_model_bound_to_ai_generated_ui_demo=true"
echo "cjgui stage381 shared component model suite: renderer_state_write=false"
