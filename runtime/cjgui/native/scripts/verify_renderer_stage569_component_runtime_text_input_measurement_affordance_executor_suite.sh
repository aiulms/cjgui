#!/usr/bin/env zsh
#
# Focused suite for stage569. It consumes stage568 layout/style preview
# surfaces and verifies shared text input measurement/affordance receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE569_TMPDIR:-/private/tmp/cjgui-stage568-stage570/stage569}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage569-component-runtime-text-input-measurement-affordance-executor-suite.packet"
STAGE568_SUITE_PACKET="${CJGUI_STAGE569_INPUT_PACKET:-${CJGUI_STAGE568_COMPONENT_RUNTIME_TEXT_INPUT_LAYOUT_STYLE_PREVIEW_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage569_component_runtime_text_input_measurement_affordance_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage569_component_runtime_text_input_measurement_affordance_executor.cj"
OWNER_LOG="$TMP_DIR/stage569-component-runtime-text-input-measurement-affordance-executor-owner.log"

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
    echo "cjgui stage569 component runtime text input measurement affordance executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage568_component_runtime_text_input_layout_style_preview_consumed=true" \
  "shared_text_input_measurement_affordance_executor_materialized=true" \
  "text_input_intrinsic_size_receipt_ledger_materialized=true" \
  "text_input_caret_rect_receipt_ledger_materialized=true" \
  "text_input_selection_rect_receipt_ledger_materialized=true" \
  "text_input_validation_adornment_receipt_ledger_materialized=true" \
  "text_input_focus_ring_receipt_ledger_materialized=true" \
  "todo_text_input_measurement_receipt_materialized=true" \
  "settings_text_input_measurement_receipt_materialized=true" \
  "ai_generated_settings_text_input_measurement_receipt_materialized=true" \
  "chat_composer_text_input_measurement_receipt_materialized=true" \
  "text_input_measurement_bound_to_stage568_preview_surfaces=true" \
  "stage570_component_runtime_text_input_demo_host_surface_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE568_SUITE_PACKET" || ! -f "$STAGE568_SUITE_PACKET" ]]; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: missing stage568 packet; set CJGUI_STAGE569_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage568_component_runtime_text_input_layout_style_preview_suite_version=1" \
  "stage567_component_runtime_text_input_demo_surface_contract_consumed=true" \
  "shared_text_input_layout_style_text_focus_preview_materialized=true" \
  "text_input_caret_selection_preview_ledger_materialized=true" \
  "text_input_validation_adorn_preview_ledger_materialized=true" \
  "text_input_focus_target_preview_ledger_materialized=true" \
  "chat_composer_text_input_layout_style_preview_surface_materialized=true" \
  "stage569_component_runtime_text_input_measurement_affordance_executor_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE568_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: runtime package build failed" >&2
  echo "cjgui stage569 component runtime text input measurement affordance executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage569_component_runtime_text_input_measurement_affordance_executor_suite_version=1"
  echo "stage568_component_runtime_text_input_layout_style_preview_suite_packet=$STAGE568_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage569_component_runtime_text_input_measurement_affordance_executor_owner_passed=true"
  echo "stage568_component_runtime_text_input_layout_style_preview_consumed=true"
  echo "stage567_component_runtime_text_input_demo_surface_contract_consumed_transitively=true"
  echo "shared_text_input_measurement_affordance_executor_materialized=true"
  echo "text_input_intrinsic_size_receipt_ledger_materialized=true"
  echo "text_input_caret_rect_receipt_ledger_materialized=true"
  echo "text_input_selection_rect_receipt_ledger_materialized=true"
  echo "text_input_validation_adornment_receipt_ledger_materialized=true"
  echo "text_input_focus_ring_receipt_ledger_materialized=true"
  echo "todo_text_input_measurement_receipt_materialized=true"
  echo "settings_text_input_measurement_receipt_materialized=true"
  echo "ai_generated_settings_text_input_measurement_receipt_materialized=true"
  echo "chat_composer_text_input_measurement_receipt_materialized=true"
  echo "text_input_measurement_bound_to_stage568_preview_surfaces=true"
  echo "component_text_input_measurement_dry_run_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage569_public_foreign_scan_passed=true"
  echo "stage569_forbidden_native_render_token_scan_passed=true"
  echo "stage569_protected_path_scan_passed=true"
  echo "stage570_component_runtime_text_input_demo_host_surface_contract_prepared=true"
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
  echo "next_route=stage570_component_runtime_text_input_demo_host_surface_contract_after_stage569"
  echo "stage569_component_runtime_text_input_measurement_affordance_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage569 component runtime text input measurement affordance executor suite: route_classification=text_input_measurement_affordance_ready"
echo "cjgui stage569 component runtime text input measurement affordance executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage569 component runtime text input measurement affordance executor suite: consumed_stage568=true"
echo "cjgui stage569 component runtime text input measurement affordance executor suite: renderer_submission=false"
