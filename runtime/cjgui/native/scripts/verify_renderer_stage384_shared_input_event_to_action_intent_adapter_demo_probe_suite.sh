#!/usr/bin/env zsh
#
# 维护注释：stage384 focused suite 消费 stage383 bridge packet，
# 验证 demo input event 可以经共享 adapter 进入 action intent，并复用 state/render refresh dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE384_TMPDIR:-/tmp/cjgui-stage384-shared-input-event-action-intent-adapter-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage384-shared-input-event-to-action-intent-adapter-demo-probe-suite.packet"
STAGE383_SUITE_PACKET="${CJGUI_STAGE384_INPUT_PACKET:-${CJGUI_STAGE383_SHARED_INPUT_EVENT_ACTION_INTENT_INPUT_PACKET:-${CJGUI_STAGE383_SHARED_ACTION_STATE_RENDER_BRIDGE_DEMO_PROBE_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage384_shared_input_event_to_action_intent_adapter_demo_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage384_shared_input_event_to_action_intent_adapter_demo_probe.cj"
OWNER_LOG="$TMP_DIR/stage384-shared-input-event-action-intent-adapter-demo-probe-owner.log"

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
    echo "cjgui stage384 shared input event to action intent adapter demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "shared_input_event_envelope_materialized=true" \
  "settings_toggle_pointer_activation_event_bound=true" \
  "todo_text_submit_input_event_bound=true" \
  "shared_input_binding_consumed_by_input_event=true" \
  "shared_focus_target_consumed_by_input_event=true" \
  "input_event_to_action_intent_adapter_materialized=true" \
  "settings_toggle_event_mapped_to_shared_action_intent=true" \
  "todo_submit_event_mapped_to_shared_action_intent=true" \
  "shared_input_binding_preserved_in_action_intent=true" \
  "shared_focus_target_preserved_in_action_intent=true" \
  "stage383_shared_action_executor_dry_run_reused=true" \
  "stage383_owner_local_state_update_dry_run_reused=true" \
  "stage383_render_command_refresh_bridge_reused=true" \
  "settings_input_event_surface_refresh_preview_materialized=true" \
  "todo_input_event_surface_refresh_preview_materialized=true" \
  "focus_after_input_event_refresh_preview_materialized=true" \
  "owner_local_preview_only=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE383_SUITE_PACKET" || ! -f "$STAGE383_SUITE_PACKET" ]]; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: missing stage383 packet; set CJGUI_STAGE384_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage383_shared_action_state_render_bridge_demo_probe_suite_version=1" \
  "stage382_shared_layout_style_input_focus_demo_probe_consumed=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "shared_demo_action_intent_materialized=true" \
  "ai_generated_settings_demo_action_consumed=true" \
  "todo_demo_action_consumed=true" \
  "shared_input_binding_consumed_by_action_intent=true" \
  "shared_focus_target_consumed_by_action_intent=true" \
  "shared_action_executor_dry_run_materialized=true" \
  "owner_local_state_update_dry_run_from_shared_action_materialized=true" \
  "settings_toggle_state_delta_materialized=true" \
  "todo_entry_state_delta_materialized=true" \
  "render_command_refresh_bridge_from_shared_action_materialized=true" \
  "shared_action_bound_to_render_command_refresh_plan=true" \
  "ai_generated_settings_demo_surface_refresh_bridge_materialized=true" \
  "todo_demo_surface_refresh_bridge_materialized=true" \
  "focus_refresh_preview_materialized=true" \
  "stage384_shared_input_event_to_action_intent_adapter_demo_probe_prepared=true" \
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
  require_file_fact "$STAGE383_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: runtime package build failed" >&2
  echo "cjgui stage384 shared input event to action intent adapter demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage383_next_route="$(fact_value "$STAGE383_SUITE_PACKET" "next_route")"

{
  echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_suite_version=1"
  echo "stage383_shared_action_state_render_bridge_demo_probe_suite_packet=$STAGE383_SUITE_PACKET"
  echo "stage383_next_route=$stage383_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_owner_passed=true"
  echo "stage383_shared_action_state_render_bridge_demo_probe_consumed=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_input_event_envelope_materialized=true"
  echo "settings_toggle_pointer_activation_event_bound=true"
  echo "todo_text_submit_input_event_bound=true"
  echo "shared_input_binding_consumed_by_input_event=true"
  echo "shared_focus_target_consumed_by_input_event=true"
  echo "input_event_to_action_intent_adapter_materialized=true"
  echo "settings_toggle_event_mapped_to_shared_action_intent=true"
  echo "todo_submit_event_mapped_to_shared_action_intent=true"
  echo "shared_input_binding_preserved_in_action_intent=true"
  echo "shared_focus_target_preserved_in_action_intent=true"
  echo "stage383_shared_action_executor_dry_run_reused=true"
  echo "stage383_owner_local_state_update_dry_run_reused=true"
  echo "stage383_render_command_refresh_bridge_reused=true"
  echo "settings_input_event_surface_refresh_preview_materialized=true"
  echo "todo_input_event_surface_refresh_preview_materialized=true"
  echo "focus_after_input_event_refresh_preview_materialized=true"
  echo "runtime_package_build_passed=true"
  echo "stage384_public_foreign_scan_passed=true"
  echo "stage384_forbidden_native_render_token_scan_passed=true"
  echo "stage384_protected_path_scan_passed=true"
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
  echo "shared_input_event_adapter_dry_run=true"
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
  echo "stage385_shared_text_input_focus_editing_demo_probe_prepared=true"
  echo "next_route=stage385_shared_text_input_focus_editing_demo_probe_after_stage384"
  echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage384 shared input event to action intent adapter demo probe suite: route_classification=shared_input_event_action_intent_adapter_ready"
echo "cjgui stage384 shared input event to action intent adapter demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage384 shared input event to action intent adapter demo probe suite: ai_generated_settings_and_todo_input_event_adapter=true"
echo "cjgui stage384 shared input event to action intent adapter demo probe suite: renderer_state_write=false"
