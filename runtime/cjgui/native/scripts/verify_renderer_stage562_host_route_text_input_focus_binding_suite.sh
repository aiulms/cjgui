#!/usr/bin/env zsh
#
# Focused suite for stage562. It consumes the stage561 packet and verifies the
# shared text-input/focus binding contract across Todo/settings/AI-generated settings.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE562_TMPDIR:-/private/tmp/cjgui-stage562-stage564/stage562}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage562-host-route-text-input-focus-binding-suite.packet"
STAGE561_SUITE_PACKET="${CJGUI_STAGE562_INPUT_PACKET:-${CJGUI_STAGE561_INTERACTION_DEMO_HOST_ROUTE_DEMO_SURFACE_EXECUTION_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage562_host_route_text_input_focus_binding_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage562_host_route_text_input_focus_binding.cj"
OWNER_LOG="$TMP_DIR/stage562-host-route-text-input-focus-binding-owner.log"

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
    echo "cjgui stage562 host route text input focus binding suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage562 host route text input focus binding suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage562 host route text input focus binding suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage562 host route text input focus binding suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage562 host route text input focus binding suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage561_host_route_demo_surface_execution_contract_consumed=true" \
  "stage557_host_route_layout_focus_measurement_executor_consumed=true" \
  "shared_host_route_text_input_focus_binding_contract_materialized=true" \
  "shared_host_route_text_input_focus_binding_helper_materialized=true" \
  "host_route_text_input_focus_binding_ledger_materialized=true" \
  "todo_host_route_text_input_focus_binding_materialized=true" \
  "settings_host_route_text_input_focus_binding_materialized=true" \
  "ai_generated_settings_host_route_text_input_focus_binding_materialized=true" \
  "host_route_text_input_focus_bound_to_stage561_execution_inputs=true" \
  "host_route_text_input_focus_bound_to_stage557_focus_traversal=true" \
  "stage563_host_route_text_edit_state_render_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE561_SUITE_PACKET" || ! -f "$STAGE561_SUITE_PACKET" ]]; then
  echo "cjgui stage562 host route text input focus binding suite: missing stage561 packet; set CJGUI_STAGE562_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage561_interaction_demo_host_route_demo_surface_execution_contract_suite_version=1" \
  "shared_host_route_demo_surface_execution_contract_materialized=true" \
  "shared_host_route_demo_surface_execution_helper_materialized=true" \
  "todo_host_route_checkable_demo_surface_execution_input_materialized=true" \
  "settings_host_route_checkable_demo_surface_execution_input_materialized=true" \
  "ai_generated_settings_host_route_checkable_demo_surface_execution_input_materialized=true" \
  "host_route_demo_surface_execution_bound_to_stage560_cycle_receipts=true" \
  "host_route_demo_surface_execution_bound_to_stage555_render_surface_contract=true" \
  "stage562_interaction_demo_host_route_text_input_focus_binding_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE561_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage562 host route text input focus binding suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage562 host route text input focus binding suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage562 host route text input focus binding suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage562 host route text input focus binding suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage562 host route text input focus binding suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage562 host route text input focus binding suite: runtime package build failed" >&2
  echo "cjgui stage562 host route text input focus binding suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage562_host_route_text_input_focus_binding_suite_version=1"
  echo "stage561_interaction_demo_host_route_demo_surface_execution_contract_suite_packet=$STAGE561_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage562_host_route_text_input_focus_binding_owner_passed=true"
  echo "stage561_host_route_demo_surface_execution_contract_consumed=true"
  echo "stage557_host_route_layout_focus_measurement_executor_consumed=true"
  echo "stage560_host_route_action_state_render_cycle_consumed_transitively=true"
  echo "stage555_host_route_render_surface_contract_consumed_transitively=true"
  echo "shared_host_route_text_input_focus_binding_contract_materialized=true"
  echo "shared_host_route_text_input_focus_binding_helper_materialized=true"
  echo "host_route_text_input_focus_binding_ledger_materialized=true"
  echo "todo_host_route_text_input_focus_binding_materialized=true"
  echo "settings_host_route_text_input_focus_binding_materialized=true"
  echo "ai_generated_settings_host_route_text_input_focus_binding_materialized=true"
  echo "host_route_text_input_focus_bound_to_stage561_execution_inputs=true"
  echo "host_route_text_input_focus_bound_to_stage557_focus_traversal=true"
  echo "host_route_text_input_focus_checkable=true"
  echo "runtime_package_build_passed=true"
  echo "stage562_public_foreign_scan_passed=true"
  echo "stage562_forbidden_native_render_token_scan_passed=true"
  echo "stage562_protected_path_scan_passed=true"
  echo "stage563_host_route_text_edit_state_render_dry_run_prepared=true"
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
  echo "next_route=stage563_host_route_text_edit_state_render_dry_run_after_stage562"
  echo "stage562_host_route_text_input_focus_binding_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage562 host route text input focus binding suite: route_classification=text_input_focus_binding_ready"
echo "cjgui stage562 host route text input focus binding suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage562 host route text input focus binding suite: consumed_stage561=true"
echo "cjgui stage562 host route text input focus binding suite: renderer_submission=false"
