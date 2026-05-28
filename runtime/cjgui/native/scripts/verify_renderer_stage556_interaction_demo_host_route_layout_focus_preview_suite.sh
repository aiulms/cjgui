#!/usr/bin/env zsh
#
# Focused suite for stage556. It consumes the stage555 host route render surface
# contract and verifies a shared host route layout/style/text/focus preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE556_TMPDIR:-/private/tmp/cjgui-stage556-stage558/stage556}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage556-interaction-demo-host-route-layout-focus-preview-suite.packet"
STAGE555_SUITE_PACKET="${CJGUI_STAGE556_INPUT_PACKET:-${CJGUI_STAGE555_INTERACTION_DEMO_HOST_ROUTE_RENDER_SURFACE_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage556_interaction_demo_host_route_layout_focus_preview_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage556_interaction_demo_host_route_layout_focus_preview.cj"
OWNER_LOG="$TMP_DIR/stage556-interaction-demo-host-route-layout-focus-preview-owner.log"

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
    echo "cjgui stage556 interaction demo host route layout focus preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage556 interaction demo host route layout focus preview suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage555_interaction_demo_host_route_render_surface_contract_consumed=true" \
  "shared_host_route_layout_style_text_focus_preview_materialized=true" \
  "host_route_layout_constraint_preview_ledger_materialized=true" \
  "host_route_style_token_preview_ledger_materialized=true" \
  "host_route_text_run_preview_ledger_materialized=true" \
  "host_route_focus_traversal_preview_ledger_materialized=true" \
  "todo_host_route_layout_focus_preview_surface_materialized=true" \
  "settings_host_route_layout_focus_preview_surface_materialized=true" \
  "ai_generated_settings_host_route_layout_focus_preview_surface_materialized=true" \
  "host_route_layout_focus_preview_bound_to_stage555_demo_surface_contract=true" \
  "host_route_layout_focus_preview_bound_to_stage554_cycle_receipt=true" \
  "host_route_layout_focus_preview_checkable=true" \
  "host_route_layout_focus_preview_template_need_reduced=true" \
  "stage557_interaction_demo_host_route_layout_focus_measurement_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE555_SUITE_PACKET" || ! -f "$STAGE555_SUITE_PACKET" ]]; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: missing stage555 packet; set CJGUI_STAGE556_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage555_interaction_demo_host_route_render_surface_contract_suite_version=1" \
  "stage554_interaction_demo_host_route_cycle_executor_consumed=true" \
  "shared_host_route_demo_surface_contract_materialized=true" \
  "todo_host_route_demo_surface_refresh_receipt_materialized=true" \
  "settings_host_route_demo_surface_refresh_receipt_materialized=true" \
  "ai_generated_settings_host_route_demo_surface_refresh_receipt_materialized=true" \
  "host_route_render_surface_bound_to_stage554_cycle_receipt=true" \
  "host_route_render_surface_bound_to_stage552_host_probe_inputs=true" \
  "host_route_render_surface_checkable=true" \
  "stage556_interaction_demo_host_route_layout_focus_preview_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE555_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage556 interaction demo host route layout focus preview suite: runtime package build failed" >&2
  echo "cjgui stage556 interaction demo host route layout focus preview suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage556_interaction_demo_host_route_layout_focus_preview_suite_version=1"
  echo "stage555_interaction_demo_host_route_render_surface_contract_suite_packet=$STAGE555_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage556_interaction_demo_host_route_layout_focus_preview_owner_passed=true"
  echo "stage555_interaction_demo_host_route_render_surface_contract_consumed=true"
  echo "stage554_interaction_demo_host_route_cycle_executor_consumed_transitively=true"
  echo "stage552_interaction_demo_host_probe_contract_consumed_transitively=true"
  echo "shared_host_route_layout_style_text_focus_preview_materialized=true"
  echo "host_route_layout_constraint_preview_ledger_materialized=true"
  echo "host_route_style_token_preview_ledger_materialized=true"
  echo "host_route_text_run_preview_ledger_materialized=true"
  echo "host_route_focus_traversal_preview_ledger_materialized=true"
  echo "todo_host_route_layout_focus_preview_surface_materialized=true"
  echo "settings_host_route_layout_focus_preview_surface_materialized=true"
  echo "ai_generated_settings_host_route_layout_focus_preview_surface_materialized=true"
  echo "host_route_layout_focus_preview_bound_to_stage555_demo_surface_contract=true"
  echo "host_route_layout_focus_preview_bound_to_stage554_cycle_receipt=true"
  echo "host_route_layout_focus_preview_checkable=true"
  echo "host_route_layout_focus_preview_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage556_public_foreign_scan_passed=true"
  echo "stage556_forbidden_native_render_token_scan_passed=true"
  echo "stage556_protected_path_scan_passed=true"
  echo "stage557_interaction_demo_host_route_layout_focus_measurement_executor_prepared=true"
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
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage557_interaction_demo_host_route_layout_focus_measurement_executor_after_stage556"
  echo "stage556_interaction_demo_host_route_layout_focus_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage556 interaction demo host route layout focus preview suite: route_classification=host_route_layout_focus_preview_ready"
echo "cjgui stage556 interaction demo host route layout focus preview suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage556 interaction demo host route layout focus preview suite: consumed_stage555=true"
echo "cjgui stage556 interaction demo host route layout focus preview suite: renderer_submission=false"
