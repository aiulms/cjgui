#!/usr/bin/env zsh
#
# Focused suite for stage508. It consumes stage507 runtime preview/probe inputs
# and verifies non-dispatching focus/input action intents for demo surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE508_TMPDIR:-/tmp/cjgui-stage508-demo-surface-refresh-focus-input-action-adapter-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage508-demo-surface-refresh-focus-input-action-adapter-suite.packet"
STAGE507_SUITE_PACKET="${CJGUI_STAGE508_INPUT_PACKET:-${CJGUI_STAGE507_DEMO_SURFACE_REFRESH_RUNTIME_PREVIEW_PROBE_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage508_demo_surface_refresh_focus_input_action_adapter_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage508_demo_surface_refresh_focus_input_action_adapter.cj"
OWNER_LOG="$TMP_DIR/stage508-demo-surface-refresh-focus-input-action-adapter-owner.log"

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
    echo "cjgui stage508 demo surface refresh focus input action adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage507_demo_surface_refresh_runtime_preview_probe_consumed=true" \
  "shared_demo_surface_refresh_runtime_preview_probe_contract_consumed=true" \
  "shared_demo_surface_refresh_runtime_preview_probe_contract_helper_consumed=true" \
  "todo_demo_surface_refresh_runtime_preview_probe_input_consumed=true" \
  "settings_demo_surface_refresh_runtime_preview_probe_input_consumed=true" \
  "ai_generated_settings_demo_surface_refresh_runtime_preview_probe_input_consumed=true" \
  "shared_demo_surface_refresh_focus_input_action_adapter_materialized=true" \
  "todo_demo_surface_refresh_runtime_focus_activation_intent_materialized=true" \
  "settings_demo_surface_refresh_runtime_toggle_intent_materialized=true" \
  "ai_generated_settings_demo_surface_refresh_runtime_submit_intent_materialized=true" \
  "runtime_preview_probe_to_focus_input_action_adapter_bound=true" \
  "demo_surface_refresh_focus_input_adapter_contract_materialized=true" \
  "focus_input_action_adapter_reusable=true" \
  "focus_input_action_adapter_owner_local=true" \
  "focus_input_action_adapter_non_dispatching=true" \
  "stage509_demo_surface_refresh_action_state_update_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE507_SUITE_PACKET" || ! -f "$STAGE507_SUITE_PACKET" ]]; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: missing stage507 packet; set CJGUI_STAGE508_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage507_demo_surface_refresh_runtime_preview_probe_suite_version=1" \
  "stage506_demo_surface_refresh_layout_execution_receipt_consumed=true" \
  "shared_demo_surface_refresh_runtime_preview_probe_contract_materialized=true" \
  "shared_demo_surface_refresh_runtime_preview_probe_contract_helper_materialized=true" \
  "shared_demo_surface_refresh_runtime_preview_probe_contract_helper_bound_to_demo_surfaces=true" \
  "todo_demo_surface_refresh_runtime_preview_probe_input_materialized=true" \
  "settings_demo_surface_refresh_runtime_preview_probe_input_materialized=true" \
  "ai_generated_settings_demo_surface_refresh_runtime_preview_probe_input_materialized=true" \
  "layout_execution_receipt_to_runtime_preview_probe_bound=true" \
  "runtime_preview_probe_reusable=true" \
  "runtime_preview_probe_owner_local=true" \
  "runtime_preview_probe_dry_run_only=true" \
  "stage508_demo_surface_refresh_focus_input_action_adapter_after_runtime_preview_prepared=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE507_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: runtime package build failed" >&2
  echo "cjgui stage508 demo surface refresh focus input action adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage507_next_route="$(fact_value "$STAGE507_SUITE_PACKET" "next_route")"

{
  echo "stage508_demo_surface_refresh_focus_input_action_adapter_suite_version=1"
  echo "stage507_demo_surface_refresh_runtime_preview_probe_suite_packet=$STAGE507_SUITE_PACKET"
  echo "stage507_next_route=$stage507_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage508_demo_surface_refresh_focus_input_action_adapter_owner_passed=true"
  echo "stage507_demo_surface_refresh_runtime_preview_probe_consumed=true"
  echo "stage506_demo_surface_refresh_layout_execution_receipt_consumed_transitively=true"
  echo "stage505_demo_surface_refresh_layout_style_preview_consumed_transitively=true"
  echo "shared_demo_surface_refresh_runtime_preview_probe_contract_consumed=true"
  echo "shared_demo_surface_refresh_runtime_preview_probe_contract_helper_consumed=true"
  echo "todo_demo_surface_refresh_runtime_preview_probe_input_consumed=true"
  echo "settings_demo_surface_refresh_runtime_preview_probe_input_consumed=true"
  echo "ai_generated_settings_demo_surface_refresh_runtime_preview_probe_input_consumed=true"
  echo "shared_demo_surface_refresh_focus_input_action_adapter_materialized=true"
  echo "todo_demo_surface_refresh_runtime_focus_activation_intent_materialized=true"
  echo "settings_demo_surface_refresh_runtime_toggle_intent_materialized=true"
  echo "ai_generated_settings_demo_surface_refresh_runtime_submit_intent_materialized=true"
  echo "runtime_preview_probe_to_focus_input_action_adapter_bound=true"
  echo "demo_surface_refresh_focus_input_adapter_contract_materialized=true"
  echo "focus_input_action_adapter_reusable=true"
  echo "focus_input_action_adapter_owner_local=true"
  echo "focus_input_action_adapter_non_dispatching=true"
  echo "runtime_package_build_passed=true"
  echo "stage508_public_foreign_scan_passed=true"
  echo "stage508_forbidden_native_render_token_scan_passed=true"
  echo "stage508_protected_path_scan_passed=true"
  echo "stage509_demo_surface_refresh_action_state_update_dry_run_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "text_shaping_enabled=false"
  echo "focus_manager_enabled=false"
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
  echo "next_route=stage509_demo_surface_refresh_action_state_update_dry_run_after_stage508"
  echo "stage508_demo_surface_refresh_focus_input_action_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage508 demo surface refresh focus input action adapter suite: route_classification=demo_surface_refresh_focus_input_action_adapter_ready"
echo "cjgui stage508 demo surface refresh focus input action adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage508 demo surface refresh focus input action adapter suite: consumed_stage507=true"
echo "cjgui stage508 demo surface refresh focus input action adapter suite: action_dispatch=false"
