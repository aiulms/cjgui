#!/usr/bin/env zsh
#
# Focused suite for stage571. It consumes stage570 text input host surfaces
# and verifies a shared non-dispatching text input event adapter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE571_TMPDIR:-/private/tmp/cjgui-stage571-stage573/stage571}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage571-component-runtime-text-input-event-adapter-suite.packet"
STAGE570_SUITE_PACKET="${CJGUI_STAGE571_INPUT_PACKET:-${CJGUI_STAGE570_COMPONENT_RUNTIME_TEXT_INPUT_DEMO_HOST_SURFACE_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage571_component_runtime_text_input_event_adapter_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage571_component_runtime_text_input_event_adapter.cj"
OWNER_LOG="$TMP_DIR/stage571-component-runtime-text-input-event-adapter-owner.log"

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
    echo "cjgui stage571 component runtime text input event adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage571 component runtime text input event adapter suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage571 component runtime text input event adapter suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage571 component runtime text input event adapter suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage571 component runtime text input event adapter suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage570_component_runtime_text_input_demo_host_surface_contract_consumed=true" \
  "shared_text_input_input_event_adapter_materialized=true" \
  "text_input_normalized_event_ledger_materialized=true" \
  "todo_text_input_keyboard_edit_event_adapted=true" \
  "settings_text_input_caret_movement_event_adapted=true" \
  "ai_generated_settings_text_input_selection_change_event_adapted=true" \
  "chat_composer_text_input_validation_trigger_event_adapted=true" \
  "text_input_event_adapter_bound_to_stage570_host_surfaces=true" \
  "text_input_event_adapter_bound_to_stage566_state_executor=true" \
  "component_runtime_text_input_event_adapter_owner_local=true" \
  "component_runtime_text_input_event_adapter_non_executing=true" \
  "component_runtime_text_input_event_adapter_non_dispatching=true" \
  "stage572_component_runtime_text_input_cycle_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE570_SUITE_PACKET" || ! -f "$STAGE570_SUITE_PACKET" ]]; then
  echo "cjgui stage571 component runtime text input event adapter suite: missing stage570 packet; set CJGUI_STAGE571_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage570_component_runtime_text_input_demo_host_surface_contract_suite_version=1" \
  "stage569_component_runtime_text_input_measurement_affordance_executor_consumed=true" \
  "shared_text_input_demo_host_surface_contract_materialized=true" \
  "shared_text_input_demo_host_surface_helper_materialized=true" \
  "todo_checkable_text_input_host_surface_materialized=true" \
  "settings_checkable_text_input_host_surface_materialized=true" \
  "ai_generated_settings_checkable_text_input_host_surface_materialized=true" \
  "chat_composer_checkable_text_input_host_surface_materialized=true" \
  "stage571_component_runtime_text_input_input_event_adapter_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE570_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage571 component runtime text input event adapter suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage571 component runtime text input event adapter suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage571 component runtime text input event adapter suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage571 component runtime text input event adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage571 component runtime text input event adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage571 component runtime text input event adapter suite: runtime package build failed" >&2
  echo "cjgui stage571 component runtime text input event adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage571_component_runtime_text_input_event_adapter_suite_version=1"
  echo "stage570_component_runtime_text_input_demo_host_surface_contract_suite_packet=$STAGE570_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage571_component_runtime_text_input_event_adapter_owner_passed=true"
  echo "stage570_component_runtime_text_input_demo_host_surface_contract_consumed=true"
  echo "stage569_component_runtime_text_input_measurement_affordance_executor_consumed_transitively=true"
  echo "shared_text_input_input_event_adapter_materialized=true"
  echo "text_input_normalized_event_ledger_materialized=true"
  echo "todo_text_input_keyboard_edit_event_adapted=true"
  echo "settings_text_input_caret_movement_event_adapted=true"
  echo "ai_generated_settings_text_input_selection_change_event_adapted=true"
  echo "chat_composer_text_input_validation_trigger_event_adapted=true"
  echo "text_input_event_adapter_bound_to_stage570_host_surfaces=true"
  echo "text_input_event_adapter_bound_to_stage566_state_executor=true"
  echo "component_runtime_text_input_event_adapter_owner_local=true"
  echo "component_runtime_text_input_event_adapter_non_executing=true"
  echo "component_runtime_text_input_event_adapter_non_dispatching=true"
  echo "runtime_package_build_passed=true"
  echo "stage571_public_foreign_scan_passed=true"
  echo "stage571_forbidden_native_render_token_scan_passed=true"
  echo "stage571_protected_path_scan_passed=true"
  echo "stage572_component_runtime_text_input_cycle_executor_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "text_shaping_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage572_component_runtime_text_input_cycle_executor_after_stage571"
  echo "stage571_component_runtime_text_input_event_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage571 component runtime text input event adapter suite: route_classification=text_input_event_adapter_ready"
echo "cjgui stage571 component runtime text input event adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage571 component runtime text input event adapter suite: consumed_stage570=true"
echo "cjgui stage571 component runtime text input event adapter suite: action_dispatch=false"
