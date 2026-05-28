#!/usr/bin/env zsh
#
# Focused suite for stage482. It consumes stage481 layout/focus route facts and
# verifies demo-surface runtime receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE482_TMPDIR:-/tmp/cjgui-stage482-demo-surface-refresh-runtime-receipt-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage482-demo-surface-refresh-runtime-receipt-suite.packet"
STAGE481_SUITE_PACKET="${CJGUI_STAGE482_INPUT_PACKET:-${CJGUI_STAGE481_DEMO_SURFACE_REFRESH_LAYOUT_FOCUS_EXECUTION_ROUTE_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage482_demo_surface_refresh_runtime_receipt_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage482_demo_surface_refresh_runtime_receipt.cj"
OWNER_LOG="$TMP_DIR/stage482-demo-surface-refresh-runtime-receipt-owner.log"

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
    echo "cjgui stage482 demo surface refresh runtime receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage482 demo surface refresh runtime receipt suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage481_demo_surface_refresh_layout_focus_execution_route_consumed=true" \
  "shared_demo_surface_refresh_layout_focus_execution_route_consumed=true" \
  "todo_demo_surface_refresh_layout_focus_pass_consumed=true" \
  "settings_demo_surface_refresh_layout_focus_pass_consumed=true" \
  "ai_generated_settings_demo_surface_refresh_layout_focus_pass_consumed=true" \
  "shared_demo_surface_refresh_runtime_receipt_materialized=true" \
  "todo_demo_surface_refresh_runtime_receipt_materialized=true" \
  "settings_demo_surface_refresh_runtime_receipt_materialized=true" \
  "ai_generated_settings_demo_surface_refresh_runtime_receipt_materialized=true" \
  "layout_focus_execution_route_to_runtime_receipt_bound=true" \
  "checkable_surface_probe_to_runtime_receipt_bound=true" \
  "demo_surface_refresh_runtime_probe_input_materialized=true" \
  "runtime_receipt_reusable=true" \
  "runtime_receipt_owner_local=true" \
  "runtime_receipt_dry_run_only=true" \
  "stage483_demo_surface_refresh_runtime_execution_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE481_SUITE_PACKET" || ! -f "$STAGE481_SUITE_PACKET" ]]; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: missing stage481 packet; set CJGUI_STAGE482_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage481_demo_surface_refresh_layout_focus_execution_route_suite_version=1" \
  "stage480_demo_surface_refresh_render_command_probe_contract_consumed=true" \
  "shared_demo_surface_refresh_layout_focus_execution_route_materialized=true" \
  "todo_demo_surface_refresh_layout_focus_pass_materialized=true" \
  "settings_demo_surface_refresh_layout_focus_pass_materialized=true" \
  "ai_generated_settings_demo_surface_refresh_layout_focus_pass_materialized=true" \
  "checkable_probe_contract_to_layout_focus_execution_route_bound=true" \
  "render_command_probe_to_layout_focus_pass_bound=true" \
  "demo_surface_refresh_text_focus_route_materialized=true" \
  "layout_focus_execution_route_reusable=true" \
  "layout_focus_execution_route_owner_local=true" \
  "layout_focus_execution_route_dry_run_only=true" \
  "stage482_demo_surface_refresh_runtime_receipt_prepared=true" \
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
  require_file_fact "$STAGE481_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage482 demo surface refresh runtime receipt suite: runtime package build failed" >&2
  echo "cjgui stage482 demo surface refresh runtime receipt suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage481_next_route="$(fact_value "$STAGE481_SUITE_PACKET" "next_route")"

{
  echo "stage482_demo_surface_refresh_runtime_receipt_suite_version=1"
  echo "stage481_demo_surface_refresh_layout_focus_execution_route_suite_packet=$STAGE481_SUITE_PACKET"
  echo "stage481_next_route=$stage481_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage482_demo_surface_refresh_runtime_receipt_owner_passed=true"
  echo "stage481_demo_surface_refresh_layout_focus_execution_route_consumed=true"
  echo "stage480_demo_surface_refresh_render_command_probe_contract_consumed_transitively=true"
  echo "stage479_demo_surface_refresh_state_render_command_bridge_consumed_transitively=true"
  echo "shared_demo_surface_refresh_layout_focus_execution_route_consumed=true"
  echo "todo_demo_surface_refresh_layout_focus_pass_consumed=true"
  echo "settings_demo_surface_refresh_layout_focus_pass_consumed=true"
  echo "ai_generated_settings_demo_surface_refresh_layout_focus_pass_consumed=true"
  echo "shared_demo_surface_refresh_runtime_receipt_materialized=true"
  echo "todo_demo_surface_refresh_runtime_receipt_materialized=true"
  echo "settings_demo_surface_refresh_runtime_receipt_materialized=true"
  echo "ai_generated_settings_demo_surface_refresh_runtime_receipt_materialized=true"
  echo "layout_focus_execution_route_to_runtime_receipt_bound=true"
  echo "checkable_surface_probe_to_runtime_receipt_bound=true"
  echo "demo_surface_refresh_runtime_probe_input_materialized=true"
  echo "runtime_receipt_reusable=true"
  echo "runtime_receipt_owner_local=true"
  echo "runtime_receipt_dry_run_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage482_public_foreign_scan_passed=true"
  echo "stage482_forbidden_native_render_token_scan_passed=true"
  echo "stage482_protected_path_scan_passed=true"
  echo "stage483_demo_surface_refresh_runtime_execution_contract_prepared=true"
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
  echo "next_route=stage483_demo_surface_refresh_runtime_execution_contract_after_stage482"
  echo "stage482_demo_surface_refresh_runtime_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage482 demo surface refresh runtime receipt suite: route_classification=demo_surface_refresh_runtime_receipt_ready"
echo "cjgui stage482 demo surface refresh runtime receipt suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage482 demo surface refresh runtime receipt suite: consumed_stage481=true"
echo "cjgui stage482 demo surface refresh runtime receipt suite: renderer_submission=false"
