#!/usr/bin/env zsh
#
# Focused suite for stage849. It consumes stage848 and records the text-input
# state delta dry-run bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE849_TMPDIR:-/private/tmp/cjgui-stage849-stage852/stage849}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage849-publishable-state-text-input-state-update-render-bridge-suite.packet"
STAGE848_FACT_SOURCE="${CJGUI_STAGE849_INPUT_PACKET:-${CJGUI_STAGE848_PUBLISHABLE_STATE_TEXT_INPUT_RUNTIME_MANAGER_FACTS:-/private/tmp/cjgui-stage845-stage848/stage848/stage848-publishable-state-text-input-runtime-manager-suite.packet}}"
STAGE848_OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage848_publishable_state_text_input_runtime_manager_owner.sh"
STAGE848_OWNER_LOG="$TMP_DIR/stage848-publishable-state-text-input-runtime-manager-owner.log"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage849_publishable_state_text_input_state_update_render_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage849-publishable-state-text-input-state-update-render-bridge-owner.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$BUILD_LOG"
: > "$PUBLIC_SCAN_LOG"
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
    echo "cjgui stage849 publishable state text input state update render bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE848_FACT_SOURCE" ]] || ! grep -F "shared_publishable_text_input_runtime_manager_materialized=true" "$STAGE848_FACT_SOURCE" >/dev/null 2>&1; then
  zsh "$STAGE848_OWNER_SCRIPT" > "$STAGE848_OWNER_LOG" 2>&1
  STAGE848_FACT_SOURCE="$STAGE848_OWNER_LOG"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage848_publishable_state_text_input_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage849_publishable_state_text_input_state_update_render_bridge_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage849_publishable_state_text_input_state_update_render_bridge_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage848_publishable_state_text_input_runtime_manager_consumed=true" \
  "stage847_publishable_state_text_input_demo_surface_consumed_transitively=true" \
  "text_input_state_delta_dry_run_materialized=true" \
  "text_insertion_state_delta_candidate_materialized=true" \
  "selection_replacement_state_delta_candidate_materialized=true" \
  "caret_selection_state_delta_candidate_materialized=true" \
  "composition_state_delta_candidate_materialized=true" \
  "text_input_rollback_token_materialized=true" \
  "text_input_state_delta_bound_to_stage848_runtime_manager=true" \
  "stage850_publishable_state_text_input_render_command_refresh_preview_prepared=true" \
  "text_input_pipeline_execution=false" \
  "text_mutation=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage848_publishable_state_text_input_runtime_manager_owner_present=true" \
  "shared_publishable_text_input_runtime_manager_materialized=true" \
  "publishable_text_input_execution_receipt_contract_materialized=true" \
  "stage849_publishable_state_text_input_state_update_render_bridge_prepared=true"; do
  require_file_fact "$STAGE848_FACT_SOURCE" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage849_publishable_state_text_input_state_update_render_bridge.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage849 publishable state text input state update render bridge suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage849 publishable state text input state update render bridge suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage849 publishable state text input state update render bridge suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage849' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage849 publishable state text input state update render bridge suite: unexpected stage849 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage849 publishable state text input state update render bridge suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage849 publishable state text input state update render bridge suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage849 publishable state text input state update render bridge suite: runtime package build failed" >&2
  echo "cjgui stage849 publishable state text input state update render bridge suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage849_publishable_state_text_input_state_update_render_bridge_suite_version=1"
  echo "stage848_fact_source=$STAGE848_FACT_SOURCE"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage849_public_declaration_scan_passed=true"
  echo "stage849_forbidden_native_render_token_scan_passed=true"
  echo "stage849_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage850_publishable_state_text_input_render_command_refresh_preview_after_stage849"
  echo "stage849_publishable_state_text_input_state_update_render_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage849 publishable state text input state update render bridge suite: route_classification=text_input_state_delta_bridge"
echo "cjgui stage849 publishable state text input state update render bridge suite: suite_packet_path=$SUITE_PACKET"
