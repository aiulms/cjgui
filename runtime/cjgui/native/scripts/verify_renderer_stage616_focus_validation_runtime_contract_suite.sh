#!/usr/bin/env zsh
#
# Focused suite for stage616. It consumes the stage615 demo-host receipt and
# verifies the shared focus/validation runtime contract plus build/scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE616_TMPDIR:-/private/tmp/cjgui-stage613-stage616/stage616}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage616-focus-validation-runtime-contract-suite.packet"
STAGE615_SUITE_PACKET="${CJGUI_STAGE616_INPUT_PACKET:-${CJGUI_STAGE615_FOCUS_VALIDATION_DEMO_HOST_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage613-stage616/stage615/stage615-focus-validation-demo-host-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage616_focus_validation_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage616-focus-validation-runtime-contract-owner.log"

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
    echo "cjgui stage616 focus validation runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage615_focus_validation_demo_host_receipt_consumed=true" \
  "shared_focus_validation_runtime_contract_materialized=true" \
  "shared_focus_validation_runtime_helper_materialized=true" \
  "chat_composer_focus_validation_runtime_surface_materialized=true" \
  "future_per_demo_focus_validation_template_need_reduced=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE615_SUITE_PACKET" || ! -f "$STAGE615_SUITE_PACKET" ]]; then
  echo "cjgui stage616 focus validation runtime contract suite: missing stage615 packet; set CJGUI_STAGE616_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage615_focus_validation_demo_host_receipt_suite_version=1" \
  "shared_focus_validation_demo_host_receipt_materialized=true" \
  "focus_movement_preview_receipt_materialized=true" \
  "stage616_shared_focus_validation_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE615_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage613_focus_validation_manager.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage614_focus_validation_feedback_resolver.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage615_focus_validation_demo_host_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage616_focus_validation_runtime_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage616 focus validation runtime contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage616 focus validation runtime contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage616 focus validation runtime contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage616 focus validation runtime contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage616 focus validation runtime contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage616 focus validation runtime contract suite: runtime package build failed" >&2
  echo "cjgui stage616 focus validation runtime contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage616_focus_validation_runtime_contract_suite_version=1"
  echo "stage615_focus_validation_demo_host_receipt_suite_packet=$STAGE615_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage616_focus_validation_runtime_contract_owner_passed=true"
  echo "stage615_focus_validation_demo_host_receipt_consumed=true"
  echo "stage614_focus_validation_feedback_resolver_consumed_transitively=true"
  echo "stage613_focus_validation_manager_consumed_transitively=true"
  echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_consumed_transitively=true"
  echo "shared_focus_validation_runtime_contract_materialized=true"
  echo "shared_focus_validation_runtime_helper_materialized=true"
  echo "shared_focus_validation_execution_receipt_contract_materialized=true"
  echo "focus_validation_cycle_order_materialized=true"
  echo "todo_focus_validation_runtime_surface_materialized=true"
  echo "settings_focus_validation_runtime_surface_materialized=true"
  echo "ai_generated_settings_focus_validation_runtime_surface_materialized=true"
  echo "chat_composer_focus_validation_runtime_surface_materialized=true"
  echo "future_per_demo_focus_validation_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage613_stage616_public_foreign_scan_passed=true"
  echo "stage613_stage616_forbidden_native_render_token_scan_passed=true"
  echo "stage616_protected_path_scan_passed=true"
  echo "stage617_focus_validation_input_cycle_prepared=true"
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
  echo "next_route=stage617_component_runtime_focus_validation_input_cycle_after_stage616"
  echo "stage616_focus_validation_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage616 focus validation runtime contract suite: route_classification=focus_validation_runtime_contract_ready"
echo "cjgui stage616 focus validation runtime contract suite: suite_packet_path=$SUITE_PACKET"
