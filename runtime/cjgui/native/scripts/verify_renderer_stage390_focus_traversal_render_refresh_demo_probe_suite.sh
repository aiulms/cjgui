#!/usr/bin/env zsh
#
# 维护注释：stage390 focused suite 消费 stage389 focus traversal key-event packet，
# 验证 focus target delta 可以接回 demo surface / RenderCommand preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE390_TMPDIR:-/tmp/cjgui-stage390-focus-traversal-render-refresh-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage390-focus-traversal-render-refresh-demo-probe-suite.packet"
STAGE389_SUITE_PACKET="${CJGUI_STAGE390_INPUT_PACKET:-${CJGUI_STAGE389_FOCUS_TRAVERSAL_RENDER_REFRESH_INPUT_PACKET:-${CJGUI_STAGE389_SHARED_FOCUS_TRAVERSAL_KEY_EVENT_DEMO_PROBE_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage390_focus_traversal_render_refresh_demo_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage390_focus_traversal_render_refresh_demo_probe.cj"
OWNER_LOG="$TMP_DIR/stage390-focus-traversal-render-refresh-demo-probe-owner.log"

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
    echo "cjgui stage390 focus traversal render refresh demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage390 focus traversal render refresh demo probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage389_shared_focus_traversal_key_event_demo_probe_consumed=true" \
  "owner_local_focus_traversal_state_delta_materialized=true" \
  "next_focus_target_preview_materialized=true" \
  "previous_focus_target_preview_materialized=true" \
  "rollback_focus_target_preview_materialized=true" \
  "focus_state_delta_bound_to_todo_and_settings_nodes=true" \
  "todo_focus_ring_surface_refresh_preview_materialized=true" \
  "settings_focus_ring_surface_refresh_preview_materialized=true" \
  "caret_focus_visibility_refresh_preview_materialized=true" \
  "focus_refresh_bound_to_stage388_commit_result_surface=true" \
  "focus_traversal_render_command_refresh_plan_materialized=true" \
  "focus_traversal_refresh_bound_to_stage383_render_bridge=true" \
  "focus_traversal_refresh_bound_to_stage388_commit_result_plan=true" \
  "focus_traversal_refresh_bound_to_stage389_key_event_adapter=true" \
  "focus_traversal_render_refresh_preview_only=true" \
  "focus_state_update_uncommitted=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE389_SUITE_PACKET" || ! -f "$STAGE389_SUITE_PACKET" ]]; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: missing stage389 packet; set CJGUI_STAGE390_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage389_shared_focus_traversal_key_event_demo_probe_suite_version=1" \
  "stage388_shared_text_edit_commit_result_render_refresh_demo_probe_consumed=true" \
  "stage387_shared_text_edit_action_commit_dry_run_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "shared_focus_traversal_key_event_envelope_materialized=true" \
  "tab_key_event_bound_to_focus_next_intent=true" \
  "shift_tab_key_event_bound_to_focus_previous_intent=true" \
  "escape_key_event_bound_to_focus_rollback_intent=true" \
  "enter_key_event_bound_to_focused_activation_intent=true" \
  "shared_focus_traversal_demo_graph_materialized=true" \
  "focus_traversal_intent_adapter_materialized=true" \
  "focus_traversal_preview_only=true" \
  "stage390_focus_traversal_render_refresh_demo_probe_prepared=true" \
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
  require_file_fact "$STAGE389_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage390 focus traversal render refresh demo probe suite: runtime package build failed" >&2
  echo "cjgui stage390 focus traversal render refresh demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage389_next_route="$(fact_value "$STAGE389_SUITE_PACKET" "next_route")"

{
  echo "stage390_focus_traversal_render_refresh_demo_probe_suite_version=1"
  echo "stage389_shared_focus_traversal_key_event_demo_probe_suite_packet=$STAGE389_SUITE_PACKET"
  echo "stage389_next_route=$stage389_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage390_focus_traversal_render_refresh_demo_probe_owner_passed=true"
  echo "stage389_shared_focus_traversal_key_event_demo_probe_consumed=true"
  echo "stage388_shared_text_edit_commit_result_render_refresh_demo_probe_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "owner_local_focus_traversal_state_delta_materialized=true"
  echo "next_focus_target_preview_materialized=true"
  echo "previous_focus_target_preview_materialized=true"
  echo "rollback_focus_target_preview_materialized=true"
  echo "focus_state_delta_bound_to_todo_and_settings_nodes=true"
  echo "todo_focus_ring_surface_refresh_preview_materialized=true"
  echo "settings_focus_ring_surface_refresh_preview_materialized=true"
  echo "caret_focus_visibility_refresh_preview_materialized=true"
  echo "focus_refresh_bound_to_stage388_commit_result_surface=true"
  echo "focus_traversal_render_command_refresh_plan_materialized=true"
  echo "focus_traversal_refresh_bound_to_stage383_render_bridge=true"
  echo "focus_traversal_refresh_bound_to_stage388_commit_result_plan=true"
  echo "focus_traversal_refresh_bound_to_stage389_key_event_adapter=true"
  echo "focus_traversal_render_refresh_preview_only=true"
  echo "focus_state_update_uncommitted=true"
  echo "runtime_package_build_passed=true"
  echo "stage390_public_foreign_scan_passed=true"
  echo "stage390_forbidden_native_render_token_scan_passed=true"
  echo "stage390_protected_path_scan_passed=true"
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
  echo "focus_traversal_render_refresh_dry_run=true"
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
  echo "stage391_keyboard_activation_action_dry_run_prepared=true"
  echo "next_route=stage391_keyboard_activation_action_dry_run_after_stage390"
  echo "stage390_focus_traversal_render_refresh_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage390 focus traversal render refresh demo probe suite: route_classification=focus_traversal_render_refresh_ready"
echo "cjgui stage390 focus traversal render refresh demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage390 focus traversal render refresh demo probe suite: consumed_stage389=true"
echo "cjgui stage390 focus traversal render refresh demo probe suite: renderer_state_write=false"
