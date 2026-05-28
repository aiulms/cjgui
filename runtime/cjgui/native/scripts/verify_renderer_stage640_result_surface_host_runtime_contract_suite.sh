#!/usr/bin/env zsh
#
# Focused suite for stage640. It consumes stage639 demo-host inspection
# surfaces, verifies the shared host runtime contract, package build, and scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE640_TMPDIR:-/private/tmp/cjgui-stage637-stage640/stage640}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage640-result-surface-host-runtime-contract-suite.packet"
STAGE639_SUITE_PACKET="${CJGUI_STAGE640_INPUT_PACKET:-${CJGUI_STAGE639_RESULT_SURFACE_DEMO_HOST_INSPECTION_SUITE_PACKET:-/private/tmp/cjgui-stage637-stage640/stage639/stage639-result-surface-demo-host-inspection-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage640_result_surface_host_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage640-result-surface-host-runtime-contract-owner.log"

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
    echo "cjgui stage640 result surface host runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage639_result_surface_demo_host_inspection_consumed=true" \
  "shared_result_surface_host_runtime_contract_materialized=true" \
  "shared_result_surface_host_runtime_helper_materialized=true" \
  "cycle_order_runtime_layout_focus_receipt_host_inspection_materialized=true" \
  "future_per_demo_result_surface_layout_focus_host_template_need_reduced=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE639_SUITE_PACKET" || ! -f "$STAGE639_SUITE_PACKET" ]]; then
  echo "cjgui stage640 result surface host runtime contract suite: missing stage639 packet; set CJGUI_STAGE640_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage639_result_surface_demo_host_inspection_suite_version=1" \
  "shared_result_surface_demo_host_inspection_input_materialized=true" \
  "chat_composer_demo_host_inspection_surface_materialized=true" \
  "stage640_result_surface_host_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE639_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage637_result_surface_layout_focus_preview.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage638_result_surface_layout_focus_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage639_result_surface_demo_host_inspection.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage640_result_surface_host_runtime_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage640 result surface host runtime contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage640 result surface host runtime contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage640 result surface host runtime contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage640 result surface host runtime contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage640 result surface host runtime contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage640 result surface host runtime contract suite: runtime package build failed" >&2
  echo "cjgui stage640 result surface host runtime contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage640_result_surface_host_runtime_contract_suite_version=1"
  echo "stage639_result_surface_demo_host_inspection_suite_packet=$STAGE639_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage640_result_surface_host_runtime_contract_owner_passed=true"
  echo "stage639_result_surface_demo_host_inspection_consumed=true"
  echo "stage638_result_surface_layout_focus_receipt_consumed_transitively=true"
  echo "stage637_result_surface_layout_focus_preview_consumed_transitively=true"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed_transitively=true"
  echo "shared_result_surface_host_runtime_contract_materialized=true"
  echo "shared_result_surface_host_runtime_helper_materialized=true"
  echo "shared_host_inspection_execution_receipt_contract_materialized=true"
  echo "cycle_order_runtime_layout_focus_receipt_host_inspection_materialized=true"
  echo "todo_result_surface_host_runtime_surface_materialized=true"
  echo "settings_result_surface_host_runtime_surface_materialized=true"
  echo "ai_generated_settings_result_surface_host_runtime_surface_materialized=true"
  echo "chat_composer_result_surface_host_runtime_surface_materialized=true"
  echo "future_per_demo_result_surface_layout_focus_host_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage637_stage640_public_foreign_scan_passed=true"
  echo "stage637_stage640_forbidden_native_render_token_scan_passed=true"
  echo "stage640_protected_path_scan_passed=true"
  echo "stage641_component_runtime_result_surface_host_input_event_adapter_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage641_component_runtime_result_surface_host_input_event_adapter_after_stage640"
  echo "stage640_result_surface_host_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage640 result surface host runtime contract suite: route_classification=result_surface_host_runtime_contract_ready"
echo "cjgui stage640 result surface host runtime contract suite: suite_packet_path=$SUITE_PACKET"
