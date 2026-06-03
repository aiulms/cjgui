#!/usr/bin/env zsh
#
# Focused suite for stage772. It consumes stage771, builds runtime/cjgui, and
# records the shared owner acceptance decision runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE772_TMPDIR:-/private/tmp/cjgui-stage769-stage772/stage772}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage772-preview-component-api-owner-acceptance-decision-runtime-manager-suite.packet"
STAGE771_SUITE_PACKET="${CJGUI_STAGE772_INPUT_PACKET:-${CJGUI_STAGE771_PREVIEW_COMPONENT_API_ACCEPTANCE_FEEDBACK_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage769-stage772/stage771/stage771-preview-component-api-acceptance-feedback-surface-suite.packet}}"
STAGE771_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage771_preview_component_api_acceptance_feedback_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage772_preview_component_api_owner_acceptance_decision_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage772-preview-component-api-owner-acceptance-decision-runtime-manager-owner.log"

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
    echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE771_SUITE_PACKET" ]] || ! grep -F "stage771_preview_component_api_acceptance_feedback_surface_suite_passed=true" "$STAGE771_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE771_TMPDIR="$TMP_DIR/stage771" zsh "$STAGE771_SUITE_SCRIPT" >/dev/null
  STAGE771_SUITE_PACKET="$TMP_DIR/stage771/stage771-preview-component-api-acceptance-feedback-surface-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage771_preview_component_api_acceptance_feedback_surface_consumed=true" \
  "stage770_preview_component_api_acceptance_decision_reducer_consumed_transitively=true" \
  "stage769_preview_component_api_owner_acceptance_boundary_consumed_transitively=true" \
  "stage768_preview_component_api_commit_runtime_manager_consumed_transitively=true" \
  "shared_preview_component_api_owner_acceptance_decision_runtime_manager_materialized=true" \
  "preview_component_api_owner_acceptance_decision_runtime_contract_materialized=true" \
  "preview_component_api_owner_acceptance_decision_execution_receipt_contract_materialized=true" \
  "cycle_order_preview_api_owner_boundary_decision_feedback_runtime_materialized=true" \
  "chat_composer_preview_component_api_owner_acceptance_decision_runtime_surface_materialized=true" \
  "owner_acceptance_decision_runtime_manager_bound_to_stage769_boundary=true" \
  "owner_acceptance_decision_runtime_manager_bound_to_stage770_decision_reducer=true" \
  "owner_acceptance_decision_runtime_manager_bound_to_stage771_feedback_surface=true" \
  "future_per_demo_owner_acceptance_decision_template_need_reduced=true" \
  "stage773_preview_component_api_commit_admission_dry_run_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage771_preview_component_api_acceptance_feedback_surface_suite_passed=true" \
  "preview_component_api_commit_result_surface_refresh_materialized=true" \
  "acceptance_feedback_surface_bound_to_stage770_decision_reducer=true"; do
  require_file_fact "$STAGE771_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage769_preview_component_api_owner_acceptance_boundary.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage770_preview_component_api_acceptance_decision_reducer.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage771_preview_component_api_acceptance_feedback_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage772_preview_component_api_owner_acceptance_decision_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage7(69|70|71|72).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: unexpected stage769-772 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_suite_version=1"
  echo "stage771_preview_component_api_acceptance_feedback_surface_suite_packet=$STAGE771_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage769_stage772_public_declaration_scan_passed=true"
  echo "stage769_stage772_forbidden_native_render_token_scan_passed=true"
  echo "stage772_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage773_preview_component_api_commit_admission_dry_run_after_stage772"
  echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: route_classification=preview_api_owner_acceptance_decision_runtime_manager"
echo "cjgui stage772 preview component api owner acceptance decision runtime manager suite: suite_packet_path=$SUITE_PACKET"
