#!/usr/bin/env zsh
#
# Focused suite for stage864. It consumes stage863, builds runtime/cjgui, and
# records the shared owner acceptance runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE864_TMPDIR:-/private/tmp/cjgui-stage861-stage864/stage864}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage864-text-input-owner-acceptance-runtime-manager-suite.packet"
STAGE863_SUITE_PACKET="${CJGUI_STAGE864_INPUT_PACKET:-${CJGUI_STAGE863_TEXT_INPUT_ACCEPTANCE_DEMO_HOST_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage861-stage864/stage863/stage863-text-input-acceptance-demo-host-surface-suite.packet}}"
STAGE863_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage863_text_input_acceptance_demo_host_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage864-text-input-owner-acceptance-runtime-manager-owner.log"

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
    echo "cjgui stage864 text input owner acceptance runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE863_SUITE_PACKET" ]] || ! grep -F "stage863_text_input_acceptance_demo_host_surface_suite_passed=true" "$STAGE863_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE863_TMPDIR="$TMP_DIR/stage863" zsh "$STAGE863_SUITE_SCRIPT" >/dev/null
  STAGE863_SUITE_PACKET="$TMP_DIR/stage863/stage863-text-input-acceptance-demo-host-surface-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage861_text_input_owner_acceptance_review_gate_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage861_text_input_owner_acceptance_review_gate_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage862_text_input_acceptance_decision_reducer_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage862_text_input_acceptance_decision_reducer_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage863_text_input_acceptance_demo_host_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage863_text_input_acceptance_demo_host_surface_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage863_text_input_acceptance_demo_host_surface_consumed=true" \
  "stage862_text_input_acceptance_decision_reducer_consumed_transitively=true" \
  "stage861_text_input_owner_acceptance_review_gate_consumed_transitively=true" \
  "stage860_owner_local_text_input_commit_runtime_manager_consumed_transitively=true" \
  "shared_text_input_owner_acceptance_runtime_manager_materialized=true" \
  "text_input_owner_acceptance_runtime_contract_materialized=true" \
  "text_input_owner_acceptance_execution_receipt_contract_materialized=true" \
  "cycle_order_owner_local_commit_review_decision_demo_runtime_materialized=true" \
  "file_browser_text_input_owner_acceptance_runtime_surface_materialized=true" \
  "text_input_owner_acceptance_runtime_manager_bound_to_stage861_review_gate=true" \
  "text_input_owner_acceptance_runtime_manager_bound_to_stage862_decision_reducer=true" \
  "text_input_owner_acceptance_runtime_manager_bound_to_stage863_demo_host_surface=true" \
  "future_per_demo_owner_acceptance_template_need_reduced=true" \
  "stage865_text_input_commit_public_api_consumption_proof_prepared=true" \
  "owner_acceptance_granted=false" \
  "text_input_commit_committed=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage863_text_input_acceptance_demo_host_surface_suite_passed=true" \
  "file_browser_text_input_acceptance_surface_materialized=true" \
  "text_input_acceptance_not_published_boundary_banner_materialized=true"; do
  require_file_fact "$STAGE863_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage861_text_input_owner_acceptance_review_gate.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage862_text_input_acceptance_decision_reducer.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage863_text_input_acceptance_demo_host_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage864_text_input_owner_acceptance_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage864 text input owner acceptance runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage864 text input owner acceptance runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage864 text input owner acceptance runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage86(1|2|3|4).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage864 text input owner acceptance runtime manager suite: unexpected stage861-864 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage864 text input owner acceptance runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage864 text input owner acceptance runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage864 text input owner acceptance runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage864 text input owner acceptance runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage864_text_input_owner_acceptance_runtime_manager_suite_version=1"
  echo "stage863_suite_packet=$STAGE863_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage861_stage864_public_declaration_scan_passed=true"
  echo "stage861_stage864_forbidden_native_render_token_scan_passed=true"
  echo "stage864_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage865_text_input_commit_public_api_consumption_proof_after_stage864"
  echo "stage864_text_input_owner_acceptance_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage864 text input owner acceptance runtime manager suite: route_classification=text_input_owner_acceptance_runtime_manager"
echo "cjgui stage864 text input owner acceptance runtime manager suite: suite_packet_path=$SUITE_PACKET"
