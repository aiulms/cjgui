#!/usr/bin/env zsh
#
# 维护注释：stage385 focused suite 消费 stage384 adapter packet，
# 验证 Todo text entry / settings focus target 可进入 shared text input editing dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE385_TMPDIR:-/tmp/cjgui-stage385-shared-text-input-focus-editing-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage385-shared-text-input-focus-editing-demo-probe-suite.packet"
STAGE384_SUITE_PACKET="${CJGUI_STAGE385_INPUT_PACKET:-${CJGUI_STAGE384_SHARED_TEXT_INPUT_FOCUS_EDITING_INPUT_PACKET:-${CJGUI_STAGE384_SHARED_INPUT_EVENT_ACTION_INTENT_ADAPTER_DEMO_PROBE_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage385_shared_text_input_focus_editing_demo_probe.cj"
OWNER_LOG="$TMP_DIR/stage385-shared-text-input-focus-editing-demo-probe-owner.log"

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
    echo "cjgui stage385 shared text input focus editing demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage385 shared text input focus editing demo probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage384_shared_input_event_to_action_intent_adapter_demo_probe_consumed=true" \
  "shared_text_input_edit_event_stream_materialized=true" \
  "todo_text_entry_character_insert_event_bound=true" \
  "todo_text_entry_backspace_edit_event_bound=true" \
  "todo_text_entry_caret_placement_event_bound=true" \
  "shared_text_model_consumed_by_editing=true" \
  "shared_input_binding_consumed_by_editing=true" \
  "shared_focus_target_consumed_by_editing=true" \
  "shared_focus_editing_state_materialized=true" \
  "settings_focus_target_preserved_during_text_editing=true" \
  "todo_text_entry_focus_target_active=true" \
  "owner_local_text_buffer_delta_materialized=true" \
  "caret_and_selection_preview_materialized=true" \
  "focus_after_editing_preview_materialized=true" \
  "text_editing_dry_run_only=true" \
  "owner_local_preview_only=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE384_SUITE_PACKET" || ! -f "$STAGE384_SUITE_PACKET" ]]; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: missing stage384 packet; set CJGUI_STAGE385_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage384_shared_input_event_to_action_intent_adapter_demo_probe_suite_version=1" \
  "stage383_shared_action_state_render_bridge_demo_probe_consumed=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "shared_input_event_envelope_materialized=true" \
  "todo_text_submit_input_event_bound=true" \
  "shared_input_binding_consumed_by_input_event=true" \
  "shared_focus_target_consumed_by_input_event=true" \
  "input_event_to_action_intent_adapter_materialized=true" \
  "todo_submit_event_mapped_to_shared_action_intent=true" \
  "stage383_owner_local_state_update_dry_run_reused=true" \
  "stage383_render_command_refresh_bridge_reused=true" \
  "todo_input_event_surface_refresh_preview_materialized=true" \
  "focus_after_input_event_refresh_preview_materialized=true" \
  "stage385_shared_text_input_focus_editing_demo_probe_prepared=true" \
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
  require_file_fact "$STAGE384_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage385 shared text input focus editing demo probe suite: runtime package build failed" >&2
  echo "cjgui stage385 shared text input focus editing demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage384_next_route="$(fact_value "$STAGE384_SUITE_PACKET" "next_route")"

{
  echo "stage385_shared_text_input_focus_editing_demo_probe_suite_version=1"
  echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_suite_packet=$STAGE384_SUITE_PACKET"
  echo "stage384_next_route=$stage384_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage385_shared_text_input_focus_editing_demo_probe_owner_passed=true"
  echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_consumed=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_text_input_edit_event_stream_materialized=true"
  echo "todo_text_entry_character_insert_event_bound=true"
  echo "todo_text_entry_backspace_edit_event_bound=true"
  echo "todo_text_entry_caret_placement_event_bound=true"
  echo "shared_text_model_consumed_by_editing=true"
  echo "shared_input_binding_consumed_by_editing=true"
  echo "shared_focus_target_consumed_by_editing=true"
  echo "shared_focus_editing_state_materialized=true"
  echo "settings_focus_target_preserved_during_text_editing=true"
  echo "todo_text_entry_focus_target_active=true"
  echo "owner_local_text_buffer_delta_materialized=true"
  echo "caret_and_selection_preview_materialized=true"
  echo "focus_after_editing_preview_materialized=true"
  echo "runtime_package_build_passed=true"
  echo "stage385_public_foreign_scan_passed=true"
  echo "stage385_forbidden_native_render_token_scan_passed=true"
  echo "stage385_protected_path_scan_passed=true"
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
  echo "shared_text_input_focus_editing_dry_run=true"
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
  echo "stage386_edited_text_render_refresh_demo_probe_prepared=true"
  echo "next_route=stage386_edited_text_render_refresh_demo_probe_after_stage385"
  echo "stage385_shared_text_input_focus_editing_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage385 shared text input focus editing demo probe suite: route_classification=shared_text_input_focus_editing_ready"
echo "cjgui stage385 shared text input focus editing demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage385 shared text input focus editing demo probe suite: todo_text_entry_focus_editing=true"
echo "cjgui stage385 shared text input focus editing demo probe suite: renderer_state_write=false"
