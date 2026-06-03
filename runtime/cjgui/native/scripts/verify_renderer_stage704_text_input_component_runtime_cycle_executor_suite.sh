#!/usr/bin/env zsh
#
# Focused suite for stage704. It consumes stage703, verifies the shared
# component runtime cycle executor, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE704_TMPDIR:-/private/tmp/cjgui-stage701-stage704/stage704}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage704-text-input-component-runtime-cycle-executor-suite.packet"
STAGE703_SUITE_PACKET="${CJGUI_STAGE704_INPUT_PACKET:-${CJGUI_STAGE703_TEXT_INPUT_COMPONENT_RUNTIME_DEMO_SURFACE_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage701-stage704/stage703/stage703-text-input-component-runtime-demo-surface-refresh-suite.packet}}"
STAGE703_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage703_text_input_component_runtime_demo_surface_refresh_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage704_text_input_component_runtime_cycle_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage704-text-input-component-runtime-cycle-executor-owner.log"

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
    echo "cjgui stage704 text input component runtime cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE703_SUITE_PACKET" ]]; then
  zsh "$STAGE703_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage703_text_input_component_runtime_demo_surface_refresh_consumed=true" \
  "shared_text_input_component_runtime_cycle_executor_materialized=true" \
  "shared_text_input_component_runtime_contract_materialized=true" \
  "text_input_component_runtime_execution_receipt_contract_materialized=true" \
  "cycle_order_component_runtime_slot_contract_binding_surface_refresh_cycle_executor_materialized=true" \
  "future_per_demo_text_input_component_runtime_template_need_reduced=true" \
  "stage705_component_runtime_input_event_normalization_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage703_text_input_component_runtime_demo_surface_refresh_suite_version=1" \
  "shared_text_input_component_runtime_demo_surface_refresh_materialized=true" \
  "component_runtime_result_surface_refresh_materialized=true" \
  "stage704_text_input_component_runtime_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE703_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage701_text_input_timeline_component_runtime_contract.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage702_text_input_component_slot_binding_adapter.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage703_text_input_component_runtime_demo_surface_refresh.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage704_text_input_component_runtime_cycle_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage704 text input component runtime cycle executor suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage704 text input component runtime cycle executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage704 text input component runtime cycle executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage704 text input component runtime cycle executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage704 text input component runtime cycle executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage704 text input component runtime cycle executor suite: runtime package build failed" >&2
  echo "cjgui stage704 text input component runtime cycle executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage704_text_input_component_runtime_cycle_executor_suite_version=1"
  echo "stage703_text_input_component_runtime_demo_surface_refresh_suite_packet=$STAGE703_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage701_stage704_public_foreign_scan_passed=true"
  echo "stage701_stage704_forbidden_native_render_token_scan_passed=true"
  echo "stage704_protected_path_scan_passed=true"
  echo "next_route=stage705_component_runtime_input_event_normalization_after_stage704"
  echo "stage704_text_input_component_runtime_cycle_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage704 text input component runtime cycle executor suite: route_classification=text_input_component_runtime_cycle_executor_ready"
echo "cjgui stage704 text input component runtime cycle executor suite: suite_packet_path=$SUITE_PACKET"
