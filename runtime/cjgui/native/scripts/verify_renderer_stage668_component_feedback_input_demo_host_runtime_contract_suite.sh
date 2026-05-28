#!/usr/bin/env zsh
#
# Focused suite for stage668. It consumes the stage667 result refresh, verifies
# the shared demo-host runtime contract, builds the runtime package, and scans
# protected paths.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE668_TMPDIR:-/private/tmp/cjgui-stage665-stage668/stage668}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage668-component-feedback-input-demo-host-runtime-contract-suite.packet"
STAGE667_SUITE_PACKET="${CJGUI_STAGE668_INPUT_PACKET:-${CJGUI_STAGE667_COMPONENT_FEEDBACK_INPUT_RESULT_SURFACE_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage665-stage668/stage667/stage667-component-feedback-input-result-surface-refresh-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage668_component_feedback_input_demo_host_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage668-component-feedback-input-demo-host-runtime-contract-owner.log"

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
    echo "cjgui stage668 component feedback input demo-host runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage667_component_feedback_input_result_surface_refresh_consumed=true" \
  "shared_feedback_input_demo_host_runtime_contract_materialized=true" \
  "shared_feedback_input_demo_host_runtime_helper_materialized=true" \
  "shared_feedback_input_demo_host_execution_receipt_contract_materialized=true" \
  "cycle_order_feedback_input_runtime_host_surface_inspection_result_runtime_receipt_materialized=true" \
  "chat_composer_feedback_input_demo_host_runtime_surface_materialized=true" \
  "future_per_demo_feedback_input_host_surface_template_need_reduced=true" \
  "stage669_feedback_input_demo_host_event_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE667_SUITE_PACKET" || ! -f "$STAGE667_SUITE_PACKET" ]]; then
  echo "cjgui stage668 component feedback input demo-host runtime contract suite: missing stage667 packet; set CJGUI_STAGE668_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage667_component_feedback_input_result_surface_refresh_suite_version=1" \
  "shared_feedback_input_result_surface_refresh_materialized=true" \
  "chat_composer_feedback_input_result_surface_refresh_materialized=true" \
  "stage668_component_feedback_input_demo_host_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE667_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage665_component_feedback_input_demo_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage666_component_feedback_input_host_inspection_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage667_component_feedback_input_result_surface_refresh.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage668_component_feedback_input_demo_host_runtime_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage668 component feedback input demo-host runtime contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage668 component feedback input demo-host runtime contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage668 component feedback input demo-host runtime contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage668 component feedback input demo-host runtime contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage668 component feedback input demo-host runtime contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage668 component feedback input demo-host runtime contract suite: runtime package build failed" >&2
  echo "cjgui stage668 component feedback input demo-host runtime contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage668_component_feedback_input_demo_host_runtime_contract_suite_version=1"
  echo "stage667_component_feedback_input_result_surface_refresh_suite_packet=$STAGE667_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage668_component_feedback_input_demo_host_runtime_contract_owner_passed=true"
  echo "stage667_component_feedback_input_result_surface_refresh_consumed=true"
  echo "stage666_component_feedback_input_host_inspection_receipt_consumed_transitively=true"
  echo "stage665_component_feedback_input_demo_host_surface_consumed_transitively=true"
  echo "stage664_interaction_feedback_input_runtime_contract_consumed_transitively=true"
  echo "shared_feedback_input_demo_host_runtime_contract_materialized=true"
  echo "shared_feedback_input_demo_host_runtime_helper_materialized=true"
  echo "shared_feedback_input_demo_host_execution_receipt_contract_materialized=true"
  echo "cycle_order_feedback_input_runtime_host_surface_inspection_result_runtime_receipt_materialized=true"
  echo "todo_feedback_input_demo_host_runtime_surface_materialized=true"
  echo "settings_feedback_input_demo_host_runtime_surface_materialized=true"
  echo "ai_generated_settings_feedback_input_demo_host_runtime_surface_materialized=true"
  echo "chat_composer_feedback_input_demo_host_runtime_surface_materialized=true"
  echo "future_per_demo_feedback_input_host_surface_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage665_stage668_public_foreign_scan_passed=true"
  echo "stage665_stage668_forbidden_native_render_token_scan_passed=true"
  echo "stage668_protected_path_scan_passed=true"
  echo "stage669_feedback_input_demo_host_event_adapter_prepared=true"
  echo "host_mutation=false"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
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
  echo "next_route=stage669_feedback_input_demo_host_event_adapter_after_stage668"
  echo "stage668_component_feedback_input_demo_host_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage668 component feedback input demo-host runtime contract suite: route_classification=feedback_input_demo_host_runtime_contract_ready"
echo "cjgui stage668 component feedback input demo-host runtime contract suite: suite_packet_path=$SUITE_PACKET"
