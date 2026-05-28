#!/usr/bin/env zsh
#
# Focused suite for stage525. It consumes stage524 layout execution receipts
# and verifies checkable runtime preview/probe inputs for demo surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE525_TMPDIR:-/tmp/cjgui-stage525-demo-surface-refresh-checkable-runtime-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage525-demo-surface-refresh-checkable-runtime-probe-suite.packet"
STAGE524_SUITE_PACKET="${CJGUI_STAGE525_INPUT_PACKET:-${CJGUI_STAGE524_DEMO_SURFACE_REFRESH_LAYOUT_EXECUTION_RECEIPT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage525_demo_surface_refresh_checkable_runtime_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage525_demo_surface_refresh_checkable_runtime_probe.cj"
OWNER_LOG="$TMP_DIR/stage525-demo-surface-refresh-checkable-runtime-probe-owner.log"

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
    echo "cjgui stage525 demo surface refresh checkable runtime probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage524_demo_surface_refresh_layout_execution_receipt_consumed=true" \
  "shared_demo_surface_refresh_checkable_layout_execution_receipt_consumed=true" \
  "demo_surface_refresh_layout_execution_helper_v4_consumed=true" \
  "todo_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true" \
  "settings_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true" \
  "ai_generated_settings_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true" \
  "shared_demo_surface_refresh_checkable_runtime_preview_probe_contract_materialized=true" \
  "demo_surface_refresh_checkable_runtime_probe_helper_v4_materialized=true" \
  "demo_surface_refresh_checkable_runtime_probe_helper_v4_bound_to_demo_surfaces=true" \
  "todo_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true" \
  "settings_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true" \
  "ai_generated_settings_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true" \
  "layout_execution_receipt_to_checkable_runtime_probe_bound=true" \
  "checkable_runtime_probe_bound_to_focus_input_adapter_next=true" \
  "demo_surface_refresh_checkable_runtime_probe_owner_local=true" \
  "demo_surface_refresh_checkable_runtime_probe_non_executing=true" \
  "stage526_demo_surface_refresh_focus_input_action_adapter_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE524_SUITE_PACKET" || ! -f "$STAGE524_SUITE_PACKET" ]]; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: missing stage524 packet; set CJGUI_STAGE525_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage524_demo_surface_refresh_layout_execution_receipt_suite_version=1" \
  "stage523_demo_surface_refresh_layout_style_preview_consumed=true" \
  "shared_demo_surface_refresh_checkable_layout_execution_receipt_materialized=true" \
  "demo_surface_refresh_layout_execution_helper_v4_materialized=true" \
  "demo_surface_refresh_layout_execution_helper_v4_bound_to_demo_surfaces=true" \
  "todo_refreshed_demo_surface_refresh_layout_execution_receipt_materialized=true" \
  "settings_refreshed_demo_surface_refresh_layout_execution_receipt_materialized=true" \
  "ai_generated_settings_refreshed_demo_surface_refresh_layout_execution_receipt_materialized=true" \
  "checkable_layout_style_preview_to_execution_receipt_bound=true" \
  "stage525_demo_surface_refresh_checkable_runtime_probe_prepared=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE524_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: runtime package build failed" >&2
  echo "cjgui stage525 demo surface refresh checkable runtime probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage524_next_route="$(fact_value "$STAGE524_SUITE_PACKET" "next_route")"

{
  echo "stage525_demo_surface_refresh_checkable_runtime_probe_suite_version=1"
  echo "stage524_demo_surface_refresh_layout_execution_receipt_suite_packet=$STAGE524_SUITE_PACKET"
  echo "stage524_next_route=$stage524_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage525_demo_surface_refresh_checkable_runtime_probe_owner_passed=true"
  echo "stage524_demo_surface_refresh_layout_execution_receipt_consumed=true"
  echo "stage523_demo_surface_refresh_layout_style_preview_consumed_transitively=true"
  echo "stage522_demo_surface_refresh_state_render_command_refresh_consumed_transitively=true"
  echo "shared_demo_surface_refresh_checkable_layout_execution_receipt_consumed=true"
  echo "demo_surface_refresh_layout_execution_helper_v4_consumed=true"
  echo "todo_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true"
  echo "settings_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true"
  echo "ai_generated_settings_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true"
  echo "shared_demo_surface_refresh_checkable_runtime_preview_probe_contract_materialized=true"
  echo "demo_surface_refresh_checkable_runtime_probe_helper_v4_materialized=true"
  echo "demo_surface_refresh_checkable_runtime_probe_helper_v4_bound_to_demo_surfaces=true"
  echo "todo_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true"
  echo "settings_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true"
  echo "ai_generated_settings_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true"
  echo "layout_execution_receipt_to_checkable_runtime_probe_bound=true"
  echo "checkable_runtime_probe_bound_to_focus_input_adapter_next=true"
  echo "demo_surface_refresh_checkable_runtime_probe_owner_local=true"
  echo "demo_surface_refresh_checkable_runtime_probe_non_executing=true"
  echo "runtime_package_build_passed=true"
  echo "stage525_public_foreign_scan_passed=true"
  echo "stage525_forbidden_native_render_token_scan_passed=true"
  echo "stage525_protected_path_scan_passed=true"
  echo "stage526_demo_surface_refresh_focus_input_action_adapter_prepared=true"
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
  echo "next_route=stage526_demo_surface_refresh_focus_input_action_adapter_after_stage525"
  echo "stage525_demo_surface_refresh_checkable_runtime_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage525 demo surface refresh checkable runtime probe suite: route_classification=demo_surface_refresh_checkable_runtime_probe_ready"
echo "cjgui stage525 demo surface refresh checkable runtime probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage525 demo surface refresh checkable runtime probe suite: consumed_stage524=true"
echo "cjgui stage525 demo surface refresh checkable runtime probe suite: renderer_submission=false"
