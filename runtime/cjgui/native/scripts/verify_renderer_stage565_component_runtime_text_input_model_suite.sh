#!/usr/bin/env zsh
#
# Focused suite for stage565. It consumes the stage564 text edit demo surface
# packet and verifies a shared component runtime text input model.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE565_TMPDIR:-/private/tmp/cjgui-stage565-stage567/stage565}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage565-component-runtime-text-input-model-suite.packet"
STAGE564_SUITE_PACKET="${CJGUI_STAGE565_INPUT_PACKET:-${CJGUI_STAGE564_HOST_ROUTE_TEXT_EDIT_DEMO_SURFACE_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage565_component_runtime_text_input_model_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage565_component_runtime_text_input_model.cj"
OWNER_LOG="$TMP_DIR/stage565-component-runtime-text-input-model-owner.log"

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
    echo "cjgui stage565 component runtime text input model suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage565 component runtime text input model suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage565 component runtime text input model suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage565 component runtime text input model suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage565 component runtime text input model suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage564_host_route_text_edit_demo_surface_contract_consumed=true" \
  "shared_component_runtime_text_input_model_materialized=true" \
  "shared_text_value_model_materialized=true" \
  "shared_text_selection_model_materialized=true" \
  "shared_caret_model_materialized=true" \
  "shared_validation_preview_model_materialized=true" \
  "todo_component_text_input_model_materialized=true" \
  "settings_component_text_input_model_materialized=true" \
  "ai_generated_settings_component_text_input_model_materialized=true" \
  "chat_composer_component_text_input_model_materialized=true" \
  "component_text_input_model_bound_to_stage564_surface_contract=true" \
  "per_demo_text_input_model_template_need_reduced=true" \
  "stage566_component_runtime_text_input_state_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE564_SUITE_PACKET" || ! -f "$STAGE564_SUITE_PACKET" ]]; then
  echo "cjgui stage565 component runtime text input model suite: missing stage564 packet; set CJGUI_STAGE565_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage564_host_route_text_edit_demo_surface_contract_suite_version=1" \
  "stage563_host_route_text_edit_state_render_dry_run_consumed=true" \
  "shared_host_route_text_edit_demo_surface_contract_materialized=true" \
  "todo_host_route_checkable_text_edit_demo_surface_input_materialized=true" \
  "settings_host_route_checkable_text_edit_demo_surface_input_materialized=true" \
  "ai_generated_settings_host_route_checkable_text_edit_demo_surface_input_materialized=true" \
  "stage565_component_runtime_text_input_model_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE564_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage565 component runtime text input model suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage565 component runtime text input model suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage565 component runtime text input model suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage565 component runtime text input model suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage565 component runtime text input model suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage565 component runtime text input model suite: runtime package build failed" >&2
  echo "cjgui stage565 component runtime text input model suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage565_component_runtime_text_input_model_suite_version=1"
  echo "stage564_host_route_text_edit_demo_surface_contract_suite_packet=$STAGE564_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage565_component_runtime_text_input_model_owner_passed=true"
  echo "stage564_host_route_text_edit_demo_surface_contract_consumed=true"
  echo "stage563_host_route_text_edit_state_render_dry_run_consumed_transitively=true"
  echo "shared_component_runtime_text_input_model_materialized=true"
  echo "shared_text_value_model_materialized=true"
  echo "shared_text_selection_model_materialized=true"
  echo "shared_caret_model_materialized=true"
  echo "shared_validation_preview_model_materialized=true"
  echo "todo_component_text_input_model_materialized=true"
  echo "settings_component_text_input_model_materialized=true"
  echo "ai_generated_settings_component_text_input_model_materialized=true"
  echo "chat_composer_component_text_input_model_materialized=true"
  echo "component_text_input_model_bound_to_stage564_surface_contract=true"
  echo "component_text_input_model_bound_to_text_edit_surface_inputs=true"
  echo "component_text_input_model_owner_local=true"
  echo "per_demo_text_input_model_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage565_public_foreign_scan_passed=true"
  echo "stage565_forbidden_native_render_token_scan_passed=true"
  echo "stage565_protected_path_scan_passed=true"
  echo "stage566_component_runtime_text_input_state_executor_prepared=true"
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
  echo "next_route=stage566_component_runtime_text_input_state_executor_after_stage565"
  echo "stage565_component_runtime_text_input_model_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage565 component runtime text input model suite: route_classification=component_runtime_text_input_model_ready"
echo "cjgui stage565 component runtime text input model suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage565 component runtime text input model suite: consumed_stage564=true"
echo "cjgui stage565 component runtime text input model suite: renderer_submission=false"
