#!/usr/bin/env zsh
#
# 维护注释：stage392 focused suite 消费 stage391 activation dry-run packet，
# 验证 keyboard activation result 可以回流到 demo surface / RenderCommand preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE392_TMPDIR:-/tmp/cjgui-stage392-keyboard-activation-result-render-refresh-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage392-keyboard-activation-result-render-refresh-demo-probe-suite.packet"
STAGE391_SUITE_PACKET="${CJGUI_STAGE392_INPUT_PACKET:-${CJGUI_STAGE391_KEYBOARD_ACTIVATION_RESULT_INPUT_PACKET:-${CJGUI_STAGE391_KEYBOARD_ACTIVATION_ACTION_DRY_RUN_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage392_keyboard_activation_result_render_refresh_demo_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage392_keyboard_activation_result_render_refresh_demo_probe.cj"
OWNER_LOG="$TMP_DIR/stage392-keyboard-activation-result-render-refresh-demo-probe-owner.log"

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
    echo "cjgui stage392 keyboard activation result render refresh demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage391_keyboard_activation_action_dry_run_consumed=true" \
  "keyboard_activation_result_envelope_materialized=true" \
  "accepted_activation_result_preview_materialized=true" \
  "rejected_activation_rollback_preview_materialized=true" \
  "activation_result_bound_to_todo_surface_refresh=true" \
  "activation_result_bound_to_settings_surface_refresh=true" \
  "activation_result_bound_to_focus_ring_refresh=true" \
  "activation_result_bound_to_stage390_focus_traversal_refresh=true" \
  "keyboard_activation_render_command_refresh_plan_materialized=true" \
  "activation_refresh_bound_to_stage383_render_bridge=true" \
  "activation_refresh_bound_to_stage391_action_dry_run=true" \
  "keyboard_activation_result_render_refresh_preview_only=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE391_SUITE_PACKET" || ! -f "$STAGE391_SUITE_PACKET" ]]; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: missing stage391 packet; set CJGUI_STAGE392_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage391_keyboard_activation_action_dry_run_suite_version=1" \
  "stage390_focus_traversal_render_refresh_demo_probe_consumed=true" \
  "stage389_shared_focus_traversal_key_event_demo_probe_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "keyboard_activation_event_envelope_materialized=true" \
  "enter_key_bound_to_focused_activation_intent=true" \
  "space_key_bound_to_focused_activation_intent=true" \
  "activation_bound_to_current_focus_target=true" \
  "focused_activation_intent_adapter_materialized=true" \
  "focused_todo_activation_mapped_to_shared_action_intent=true" \
  "focused_settings_activation_mapped_to_shared_action_intent=true" \
  "keyboard_activation_owner_acceptance_gate_materialized=true" \
  "keyboard_activation_state_update_dry_run_materialized=true" \
  "todo_activation_state_delta_preview_materialized=true" \
  "settings_activation_state_delta_preview_materialized=true" \
  "activation_state_update_bound_to_stage383_action_executor=true" \
  "activation_state_update_bound_to_stage390_focus_traversal_refresh=true" \
  "keyboard_activation_dry_run_uncommitted=true" \
  "stage392_keyboard_activation_result_render_refresh_demo_probe_prepared=true" \
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
  require_file_fact "$STAGE391_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: runtime package build failed" >&2
  echo "cjgui stage392 keyboard activation result render refresh demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage391_next_route="$(fact_value "$STAGE391_SUITE_PACKET" "next_route")"

{
  echo "stage392_keyboard_activation_result_render_refresh_demo_probe_suite_version=1"
  echo "stage391_keyboard_activation_action_dry_run_suite_packet=$STAGE391_SUITE_PACKET"
  echo "stage391_next_route=$stage391_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage392_keyboard_activation_result_render_refresh_demo_probe_owner_passed=true"
  echo "stage391_keyboard_activation_action_dry_run_consumed=true"
  echo "stage390_focus_traversal_render_refresh_demo_probe_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "keyboard_activation_result_envelope_materialized=true"
  echo "accepted_activation_result_preview_materialized=true"
  echo "rejected_activation_rollback_preview_materialized=true"
  echo "activation_result_bound_to_todo_surface_refresh=true"
  echo "activation_result_bound_to_settings_surface_refresh=true"
  echo "activation_result_bound_to_focus_ring_refresh=true"
  echo "activation_result_bound_to_stage390_focus_traversal_refresh=true"
  echo "keyboard_activation_render_command_refresh_plan_materialized=true"
  echo "activation_refresh_bound_to_stage383_render_bridge=true"
  echo "activation_refresh_bound_to_stage391_action_dry_run=true"
  echo "keyboard_activation_result_render_refresh_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage392_public_foreign_scan_passed=true"
  echo "stage392_forbidden_native_render_token_scan_passed=true"
  echo "stage392_protected_path_scan_passed=true"
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
  echo "keyboard_activation_result_render_refresh_dry_run=true"
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
  echo "stage393_shared_activation_executor_helper_prepared=true"
  echo "next_route=stage393_shared_activation_executor_helper_after_stage392"
  echo "stage392_keyboard_activation_result_render_refresh_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage392 keyboard activation result render refresh demo probe suite: route_classification=keyboard_activation_result_render_refresh_ready"
echo "cjgui stage392 keyboard activation result render refresh demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage392 keyboard activation result render refresh demo probe suite: consumed_stage391=true"
echo "cjgui stage392 keyboard activation result render refresh demo probe suite: renderer_state_write=false"
