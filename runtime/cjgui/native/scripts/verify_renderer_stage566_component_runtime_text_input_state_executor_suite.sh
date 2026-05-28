#!/usr/bin/env zsh
#
# Focused suite for stage566. It consumes the stage565 text input model packet
# and verifies shared owner-local text input state execution receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE566_TMPDIR:-/private/tmp/cjgui-stage565-stage567/stage566}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage566-component-runtime-text-input-state-executor-suite.packet"
STAGE565_SUITE_PACKET="${CJGUI_STAGE566_INPUT_PACKET:-${CJGUI_STAGE565_COMPONENT_RUNTIME_TEXT_INPUT_MODEL_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage566_component_runtime_text_input_state_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage566_component_runtime_text_input_state_executor.cj"
OWNER_LOG="$TMP_DIR/stage566-component-runtime-text-input-state-executor-owner.log"

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
    echo "cjgui stage566 component runtime text input state executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage566 component runtime text input state executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage566 component runtime text input state executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage566 component runtime text input state executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage566 component runtime text input state executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage565_component_runtime_text_input_model_consumed=true" \
  "shared_component_text_input_state_executor_materialized=true" \
  "text_value_state_delta_dry_run_ledger_materialized=true" \
  "selection_caret_transition_ledger_materialized=true" \
  "validation_result_preview_ledger_materialized=true" \
  "text_input_render_command_refresh_preview_ledger_materialized=true" \
  "todo_component_text_input_state_receipt_materialized=true" \
  "settings_component_text_input_state_receipt_materialized=true" \
  "ai_generated_settings_component_text_input_state_receipt_materialized=true" \
  "chat_composer_component_text_input_state_receipt_materialized=true" \
  "component_text_input_state_dry_run_only=true" \
  "stage567_component_runtime_text_input_demo_surface_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE565_SUITE_PACKET" || ! -f "$STAGE565_SUITE_PACKET" ]]; then
  echo "cjgui stage566 component runtime text input state executor suite: missing stage565 packet; set CJGUI_STAGE566_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage565_component_runtime_text_input_model_suite_version=1" \
  "stage564_host_route_text_edit_demo_surface_contract_consumed=true" \
  "shared_component_runtime_text_input_model_materialized=true" \
  "shared_text_value_model_materialized=true" \
  "shared_text_selection_model_materialized=true" \
  "chat_composer_component_text_input_model_materialized=true" \
  "stage566_component_runtime_text_input_state_executor_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE565_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage566 component runtime text input state executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage566 component runtime text input state executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage566 component runtime text input state executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage566 component runtime text input state executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage566 component runtime text input state executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage566 component runtime text input state executor suite: runtime package build failed" >&2
  echo "cjgui stage566 component runtime text input state executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage566_component_runtime_text_input_state_executor_suite_version=1"
  echo "stage565_component_runtime_text_input_model_suite_packet=$STAGE565_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage566_component_runtime_text_input_state_executor_owner_passed=true"
  echo "stage565_component_runtime_text_input_model_consumed=true"
  echo "stage564_host_route_text_edit_demo_surface_contract_consumed_transitively=true"
  echo "shared_component_text_input_state_executor_materialized=true"
  echo "text_input_action_ledger_materialized=true"
  echo "text_value_state_delta_dry_run_ledger_materialized=true"
  echo "selection_caret_transition_ledger_materialized=true"
  echo "validation_result_preview_ledger_materialized=true"
  echo "text_input_render_command_refresh_preview_ledger_materialized=true"
  echo "todo_component_text_input_state_receipt_materialized=true"
  echo "settings_component_text_input_state_receipt_materialized=true"
  echo "ai_generated_settings_component_text_input_state_receipt_materialized=true"
  echo "chat_composer_component_text_input_state_receipt_materialized=true"
  echo "text_input_state_executor_bound_to_stage565_model=true"
  echo "text_input_state_executor_bound_to_stage563_dry_run=true"
  echo "component_text_input_state_dry_run_only=true"
  echo "component_text_input_render_refresh_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage566_public_foreign_scan_passed=true"
  echo "stage566_forbidden_native_render_token_scan_passed=true"
  echo "stage566_protected_path_scan_passed=true"
  echo "stage567_component_runtime_text_input_demo_surface_contract_prepared=true"
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
  echo "next_route=stage567_component_runtime_text_input_demo_surface_contract_after_stage566"
  echo "stage566_component_runtime_text_input_state_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage566 component runtime text input state executor suite: route_classification=component_text_input_state_executor_ready"
echo "cjgui stage566 component runtime text input state executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage566 component runtime text input state executor suite: consumed_stage565=true"
echo "cjgui stage566 component runtime text input state executor suite: renderer_submission=false"
