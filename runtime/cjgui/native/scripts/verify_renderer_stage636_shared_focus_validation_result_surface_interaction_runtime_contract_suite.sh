#!/usr/bin/env zsh
#
# Focused suite for stage636. It consumes stage635 render-refresh receipts,
# verifies the reusable runtime contract, package build, and protected scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE636_TMPDIR:-/private/tmp/cjgui-stage633-stage636/stage636}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage636-shared-focus-validation-result-surface-interaction-runtime-contract-suite.packet"
STAGE635_SUITE_PACKET="${CJGUI_STAGE636_INPUT_PACKET:-${CJGUI_STAGE635_FOCUS_VALIDATION_RESULT_SURFACE_STATE_RENDER_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage633-stage636/stage635/stage635-focus-validation-result-surface-state-render-refresh-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage636_shared_focus_validation_result_surface_interaction_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage636-shared-focus-validation-result-surface-interaction-runtime-contract-owner.log"

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
    echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage635_focus_validation_result_surface_state_render_refresh_consumed=true" \
  "shared_focus_validation_result_surface_interaction_runtime_contract_materialized=true" \
  "shared_focus_validation_result_surface_interaction_runtime_helper_materialized=true" \
  "cycle_order_result_surface_interaction_action_state_render_refresh_runtime_receipt_materialized=true" \
  "future_per_demo_result_surface_interaction_template_need_reduced=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE635_SUITE_PACKET" || ! -f "$STAGE635_SUITE_PACKET" ]]; then
  echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: missing stage635 packet; set CJGUI_STAGE636_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage635_focus_validation_result_surface_state_render_refresh_suite_version=1" \
  "shared_result_surface_state_render_refresh_executor_materialized=true" \
  "chat_composer_result_surface_render_refresh_receipt_materialized=true" \
  "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE635_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage633_focus_validation_result_surface_interaction_bridge.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage634_focus_validation_result_surface_action_state_adapter.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage635_focus_validation_result_surface_state_render_refresh.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage636_shared_focus_validation_result_surface_interaction_runtime_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: runtime package build failed" >&2
  echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_suite_version=1"
  echo "stage635_focus_validation_result_surface_state_render_refresh_suite_packet=$STAGE635_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_owner_passed=true"
  echo "stage635_focus_validation_result_surface_state_render_refresh_consumed=true"
  echo "stage634_focus_validation_result_surface_action_state_adapter_consumed_transitively=true"
  echo "stage633_focus_validation_result_surface_interaction_bridge_consumed_transitively=true"
  echo "stage632_shared_focus_validation_result_surface_runtime_contract_consumed_transitively=true"
  echo "shared_focus_validation_result_surface_interaction_runtime_contract_materialized=true"
  echo "shared_focus_validation_result_surface_interaction_runtime_helper_materialized=true"
  echo "shared_result_surface_interaction_execution_receipt_contract_materialized=true"
  echo "cycle_order_result_surface_interaction_action_state_render_refresh_runtime_receipt_materialized=true"
  echo "todo_result_surface_interaction_runtime_surface_materialized=true"
  echo "settings_result_surface_interaction_runtime_surface_materialized=true"
  echo "ai_generated_settings_result_surface_interaction_runtime_surface_materialized=true"
  echo "chat_composer_result_surface_interaction_runtime_surface_materialized=true"
  echo "future_per_demo_result_surface_interaction_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage633_stage636_public_foreign_scan_passed=true"
  echo "stage633_stage636_forbidden_native_render_token_scan_passed=true"
  echo "stage636_protected_path_scan_passed=true"
  echo "stage637_component_runtime_result_surface_interaction_layout_focus_preview_prepared=true"
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
  echo "next_route=stage637_component_runtime_result_surface_interaction_layout_focus_preview_after_stage636"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: route_classification=shared_result_surface_interaction_runtime_contract_ready"
echo "cjgui stage636 shared focus validation result surface interaction runtime contract suite: suite_packet_path=$SUITE_PACKET"
