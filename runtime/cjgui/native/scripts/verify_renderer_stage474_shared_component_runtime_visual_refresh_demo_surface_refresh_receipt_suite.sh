#!/usr/bin/env zsh
#
# Focused suite for stage474. It consumes stage473 RenderCommand refresh and
# verifies checkable demo-surface refresh receipts for shared runtime surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE474_TMPDIR:-/tmp/cjgui-stage474-shared-component-runtime-visual-refresh-demo-surface-refresh-receipt-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage474-shared-component-runtime-visual-refresh-demo-surface-refresh-receipt-suite.packet"
STAGE473_SUITE_PACKET="${CJGUI_STAGE474_INPUT_PACKET:-${CJGUI_STAGE473_SHARED_COMPONENT_RUNTIME_VISUAL_REFRESH_INTERACTION_RENDER_COMMAND_REFRESH_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt.cj"
OWNER_LOG="$TMP_DIR/stage474-shared-component-runtime-visual-refresh-demo-surface-refresh-receipt-owner.log"

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
    echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_consumed=true" \
  "shared_component_runtime_visual_refresh_interaction_render_command_refresh_consumed=true" \
  "todo_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true" \
  "settings_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true" \
  "ai_generated_settings_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true" \
  "shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true" \
  "todo_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true" \
  "settings_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true" \
  "ai_generated_settings_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true" \
  "shared_demo_surface_refresh_execution_contract_materialized=true" \
  "render_command_refresh_to_demo_surface_refresh_receipt_bound=true" \
  "demo_surface_refresh_receipt_to_probe_input_bound=true" \
  "demo_surface_refresh_receipt_reusable=true" \
  "demo_surface_refresh_receipt_checkable=true" \
  "stage475_shared_component_runtime_demo_surface_refresh_layout_style_preview_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE473_SUITE_PACKET" || ! -f "$STAGE473_SUITE_PACKET" ]]; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: missing stage473 packet; set CJGUI_STAGE474_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_suite_version=1" \
  "stage472_shared_component_runtime_visual_refresh_interaction_state_update_bridge_consumed=true" \
  "shared_component_runtime_visual_refresh_interaction_render_command_refresh_materialized=true" \
  "todo_runtime_visual_refresh_interaction_render_command_probe_input_materialized=true" \
  "settings_runtime_visual_refresh_interaction_render_command_probe_input_materialized=true" \
  "ai_generated_settings_runtime_visual_refresh_interaction_render_command_probe_input_materialized=true" \
  "interaction_state_update_to_render_command_refresh_bound=true" \
  "render_command_refresh_to_demo_surface_refresh_receipt_bound=true" \
  "interaction_render_command_bridge_reusable=true" \
  "interaction_render_command_bridge_preview_only=true" \
  "stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_prepared=true" \
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
  require_file_fact "$STAGE473_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: runtime package build failed" >&2
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage473_next_route="$(fact_value "$STAGE473_SUITE_PACKET" "next_route")"

{
  echo "stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_suite_version=1"
  echo "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_suite_packet=$STAGE473_SUITE_PACKET"
  echo "stage473_next_route=$stage473_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_owner_passed=true"
  echo "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_consumed=true"
  echo "stage472_shared_component_runtime_visual_refresh_interaction_state_update_bridge_consumed_transitively=true"
  echo "stage471_shared_component_runtime_visual_refresh_interaction_execution_contract_consumed_transitively=true"
  echo "shared_component_runtime_visual_refresh_interaction_render_command_refresh_consumed=true"
  echo "todo_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true"
  echo "settings_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true"
  echo "ai_generated_settings_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true"
  echo "shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
  echo "todo_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
  echo "settings_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
  echo "ai_generated_settings_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
  echo "shared_demo_surface_refresh_execution_contract_materialized=true"
  echo "render_command_refresh_to_demo_surface_refresh_receipt_bound=true"
  echo "demo_surface_refresh_receipt_to_probe_input_bound=true"
  echo "demo_surface_refresh_receipt_reusable=true"
  echo "demo_surface_refresh_receipt_checkable=true"
  echo "runtime_package_build_passed=true"
  echo "stage474_public_foreign_scan_passed=true"
  echo "stage474_forbidden_native_render_token_scan_passed=true"
  echo "stage474_protected_path_scan_passed=true"
  echo "stage475_shared_component_runtime_demo_surface_refresh_layout_style_preview_prepared=true"
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
  echo "next_route=stage475_shared_component_runtime_demo_surface_refresh_layout_style_preview_after_stage474"
  echo "stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: route_classification=shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_ready"
echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: consumed_stage473=true"
echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt suite: renderer_submission=false"
