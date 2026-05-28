#!/usr/bin/env zsh
#
# Focused suite for stage570. It consumes stage569 text input measurement
# receipts and verifies a shared demo-host surface contract/helper.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE570_TMPDIR:-/private/tmp/cjgui-stage568-stage570/stage570}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage570-component-runtime-text-input-demo-host-surface-contract-suite.packet"
STAGE569_SUITE_PACKET="${CJGUI_STAGE570_INPUT_PACKET:-${CJGUI_STAGE569_COMPONENT_RUNTIME_TEXT_INPUT_MEASUREMENT_AFFORDANCE_EXECUTOR_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage570_component_runtime_text_input_demo_host_surface_contract_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage570_component_runtime_text_input_demo_host_surface_contract.cj"
OWNER_LOG="$TMP_DIR/stage570-component-runtime-text-input-demo-host-surface-contract-owner.log"

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
    echo "cjgui stage570 component runtime text input demo host surface contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage570 component runtime text input demo host surface contract suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage569_component_runtime_text_input_measurement_affordance_executor_consumed=true" \
  "shared_text_input_demo_host_surface_contract_materialized=true" \
  "shared_text_input_demo_host_surface_helper_materialized=true" \
  "todo_checkable_text_input_host_surface_materialized=true" \
  "settings_checkable_text_input_host_surface_materialized=true" \
  "ai_generated_settings_checkable_text_input_host_surface_materialized=true" \
  "chat_composer_checkable_text_input_host_surface_materialized=true" \
  "demo_host_surface_bound_to_stage569_measurements=true" \
  "demo_host_surface_bound_to_stage568_preview=true" \
  "demo_host_surface_bound_to_stage567_surface_contract=true" \
  "per_demo_text_input_host_surface_template_need_reduced=true" \
  "stage571_component_runtime_text_input_input_event_adapter_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE569_SUITE_PACKET" || ! -f "$STAGE569_SUITE_PACKET" ]]; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: missing stage569 packet; set CJGUI_STAGE570_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage569_component_runtime_text_input_measurement_affordance_executor_suite_version=1" \
  "stage568_component_runtime_text_input_layout_style_preview_consumed=true" \
  "shared_text_input_measurement_affordance_executor_materialized=true" \
  "text_input_intrinsic_size_receipt_ledger_materialized=true" \
  "text_input_caret_rect_receipt_ledger_materialized=true" \
  "text_input_selection_rect_receipt_ledger_materialized=true" \
  "text_input_validation_adornment_receipt_ledger_materialized=true" \
  "chat_composer_text_input_measurement_receipt_materialized=true" \
  "stage570_component_runtime_text_input_demo_host_surface_contract_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE569_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage570 component runtime text input demo host surface contract suite: runtime package build failed" >&2
  echo "cjgui stage570 component runtime text input demo host surface contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage570_component_runtime_text_input_demo_host_surface_contract_suite_version=1"
  echo "stage569_component_runtime_text_input_measurement_affordance_executor_suite_packet=$STAGE569_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage570_component_runtime_text_input_demo_host_surface_contract_owner_passed=true"
  echo "stage569_component_runtime_text_input_measurement_affordance_executor_consumed=true"
  echo "stage568_component_runtime_text_input_layout_style_preview_consumed_transitively=true"
  echo "stage567_component_runtime_text_input_demo_surface_contract_consumed_transitively=true"
  echo "shared_text_input_demo_host_surface_contract_materialized=true"
  echo "shared_text_input_demo_host_surface_helper_materialized=true"
  echo "todo_checkable_text_input_host_surface_materialized=true"
  echo "settings_checkable_text_input_host_surface_materialized=true"
  echo "ai_generated_settings_checkable_text_input_host_surface_materialized=true"
  echo "chat_composer_checkable_text_input_host_surface_materialized=true"
  echo "demo_host_surface_bound_to_stage569_measurements=true"
  echo "demo_host_surface_bound_to_stage568_preview=true"
  echo "demo_host_surface_bound_to_stage567_surface_contract=true"
  echo "per_demo_text_input_host_surface_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage570_public_foreign_scan_passed=true"
  echo "stage570_forbidden_native_render_token_scan_passed=true"
  echo "stage570_protected_path_scan_passed=true"
  echo "stage571_component_runtime_text_input_input_event_adapter_prepared=true"
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
  echo "next_route=stage571_component_runtime_text_input_input_event_adapter_after_stage570"
  echo "stage570_component_runtime_text_input_demo_host_surface_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage570 component runtime text input demo host surface contract suite: route_classification=text_input_demo_host_surface_contract_ready"
echo "cjgui stage570 component runtime text input demo host surface contract suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage570 component runtime text input demo host surface contract suite: consumed_stage569=true"
echo "cjgui stage570 component runtime text input demo host surface contract suite: renderer_submission=false"
