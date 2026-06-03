#!/usr/bin/env zsh
#
# Focused suite for stage692. It consumes stage691, builds runtime/cjgui, and scans protected boundaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE692_TMPDIR:-/private/tmp/cjgui-stage689-stage692/stage692}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage692-replay-host-text-input-demo-host-cycle-executor-suite.packet"
STAGE691_SUITE_PACKET="${CJGUI_STAGE692_INPUT_PACKET:-${CJGUI_STAGE691_REPLAY_HOST_TEXT_INPUT_EXECUTION_RESULT_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage689-stage692/stage691/stage691-replay-host-text-input-execution-result-surface-suite.packet}}"
STAGE691_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage691_replay_host_text_input_execution_result_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage692_replay_host_text_input_demo_host_cycle_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage692-replay-host-text-input-demo-host-cycle-executor-owner.log"

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
    echo "cjgui stage692 replay host text input demo-host cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE691_SUITE_PACKET" ]]; then
  zsh "$STAGE691_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage691_replay_host_text_input_execution_result_surface_consumed=true" \
  "stage690_replay_host_text_input_host_event_adapter_consumed_transitively=true" \
  "stage689_replay_host_text_input_demo_host_integration_consumed_transitively=true" \
  "stage688_replay_host_text_input_runtime_contract_consumed_transitively=true" \
  "shared_replay_host_text_input_demo_host_cycle_executor_materialized=true" \
  "shared_replay_host_text_input_demo_host_cycle_runtime_contract_materialized=true" \
  "shared_replay_host_text_input_demo_host_cycle_execution_receipt_contract_materialized=true" \
  "cycle_order_text_input_runtime_host_integration_event_queue_execution_result_surface_materialized=true" \
  "chat_composer_replay_host_text_input_demo_host_cycle_runtime_surface_materialized=true" \
  "future_per_demo_text_input_demo_host_template_need_reduced=true" \
  "stage693_replay_host_text_input_event_replay_surface_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage691_replay_host_text_input_execution_result_surface_suite_version=1" \
  "shared_replay_host_text_input_execution_result_receipt_materialized=true" \
  "stage692_replay_host_text_input_demo_host_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE691_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage689_replay_host_text_input_demo_host_integration.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage690_replay_host_text_input_host_event_adapter.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage691_replay_host_text_input_execution_result_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage692_replay_host_text_input_demo_host_cycle_executor.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage692 replay host text input demo-host cycle executor suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage692 replay host text input demo-host cycle executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage692 replay host text input demo-host cycle executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage692 replay host text input demo-host cycle executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage692 replay host text input demo-host cycle executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage692 replay host text input demo-host cycle executor suite: runtime package build failed" >&2
  echo "cjgui stage692 replay host text input demo-host cycle executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage692_replay_host_text_input_demo_host_cycle_executor_suite_version=1"
  echo "stage691_replay_host_text_input_execution_result_surface_suite_packet=$STAGE691_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage689_stage692_public_foreign_scan_passed=true"
  echo "stage689_stage692_forbidden_native_render_token_scan_passed=true"
  echo "stage692_protected_path_scan_passed=true"
  echo "text_shaping_enabled=false"
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
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage693_replay_host_text_input_event_replay_surface_after_stage692"
  echo "stage692_replay_host_text_input_demo_host_cycle_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage692 replay host text input demo-host cycle executor suite: route_classification=text_input_demo_host_cycle_executor_ready"
echo "cjgui stage692 replay host text input demo-host cycle executor suite: suite_packet_path=$SUITE_PACKET"
