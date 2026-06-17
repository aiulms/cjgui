#!/usr/bin/env zsh
#
# Focused suite for stage892. It consumes stage891, builds runtime/cjgui, and
# records the shared experimental public component commit API runtime manager.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE892_TMPDIR:-/private/tmp/cjgui-stage889-stage892/stage892}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage892-component-commit-api-runtime-manager-suite.packet"
STAGE891_SUITE_PACKET="${CJGUI_STAGE892_INPUT_PACKET:-${CJGUI_STAGE891_COMPONENT_COMMIT_API_DEMO_CONSUMPTION_SUITE_PACKET:-/private/tmp/cjgui-stage889-stage892/stage891/stage891-component-commit-api-demo-consumption-suite.packet}}"
STAGE891_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage891_component_commit_api_demo_consumption_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage892_component_commit_api_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage892-component-commit-api-runtime-manager-owner.log"

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
    echo "cjgui stage892 component commit api runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE891_SUITE_PACKET" ]] || ! grep -F "stage891_component_commit_api_demo_consumption_suite_passed=true" "$STAGE891_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE891_TMPDIR="$TMP_DIR/stage891" zsh "$STAGE891_SUITE_SCRIPT" >/dev/null
  STAGE891_SUITE_PACKET="$TMP_DIR/stage891/stage891-component-commit-api-demo-consumption-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage889_minimal_public_component_commit_api_readiness_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage889_minimal_public_component_commit_api_readiness_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage890_experimental_component_commit_api_declaration_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage890_experimental_component_commit_api_declaration_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage891_component_commit_api_demo_consumption_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage891_component_commit_api_demo_consumption_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage892_component_commit_api_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage892_component_commit_api_runtime_manager_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage891_component_commit_api_demo_consumption_suite_passed=true" \
  "file_browser_component_commit_api_demo_surface_materialized=true" \
  "demo_consumption_bound_to_experimental_commit_api=true" \
  "stage892_component_commit_api_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE891_SUITE_PACKET" "$fact"
done

for fact in \
  "stage891_component_commit_api_demo_consumption_consumed=true" \
  "stage890_experimental_component_commit_api_declaration_consumed_transitively=true" \
  "stage889_minimal_public_component_commit_api_readiness_consumed_transitively=true" \
  "stage888_owner_local_accepted_commit_publication_runtime_manager_consumed_transitively=true" \
  "shared_component_commit_api_runtime_manager_materialized=true" \
  "component_commit_api_runtime_contract_materialized=true" \
  "component_commit_api_execution_receipt_contract_materialized=true" \
  "cycle_order_component_commit_api_readiness_declaration_demo_runtime_materialized=true" \
  "file_browser_component_commit_api_runtime_surface_materialized=true" \
  "common_component_commit_api_executor_materialized=true" \
  "component_commit_api_demo_runtime_bridge_materialized=true" \
  "future_per_demo_component_commit_api_template_need_reduced=true" \
  "stage893_component_commit_api_owner_local_commit_bridge_prepared=true" \
  "public_surface_cjguiExperimentalComponentCommitApiReady_materialized=true" \
  "new_public_surface_added=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "state_store_write_executed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage889_minimal_public_component_commit_api_readiness.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage890_experimental_component_commit_api_declaration.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage891_component_commit_api_demo_consumption.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage892_component_commit_api_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage892 component commit api runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func' >/dev/null 2>&1; then
    echo "cjgui stage892 component commit api runtime manager suite: unexpected foreign declaration in $src" >&2
    exit 11
  fi
  if [[ "$src" != *"stage890_experimental_component_commit_api_declaration.cj" ]] && \
    sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage892 component commit api runtime manager suite: unexpected public declaration in $src" >&2
    exit 12
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage892 component commit api runtime manager suite: forbidden native/render token found in $src" >&2
    exit 13
  fi
done

if ! sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$ROOT_DIR/src/runtime_renderer_stage890_experimental_component_commit_api_declaration.cj" \
  | grep -E '^public[[:space:]]+func[[:space:]]+cjguiExperimentalComponentCommitApiReady\(\):[[:space:]]+Bool' >/dev/null 2>&1; then
  echo "cjgui stage892 component commit api runtime manager suite: missing exact experimental component commit public function" >&2
  exit 14
fi

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentCommitApiReady"
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalQueueSubmitShellReady"
if grep -E 'runtime_renderer_stage88(9|9).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage892 component commit api runtime manager suite: unexpected stage889 public declaration" >&2
  exit 15
fi
if grep -E 'runtime_renderer_stage89(1|2).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage892 component commit api runtime manager suite: unexpected stage891-stage892 public declaration" >&2
  exit 16
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage892 component commit api runtime manager suite: protected production bridge/state path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage892 component commit api runtime manager suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage892 component commit api runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage892 component commit api runtime manager suite: log=$BUILD_LOG" >&2
  exit 19
fi

{
  echo "stage892_component_commit_api_runtime_manager_suite_version=1"
  echo "stage891_suite_packet=$STAGE891_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage889_stage892_public_declaration_scan_passed=true"
  echo "stage889_stage892_forbidden_native_render_token_scan_passed=true"
  echo "stage892_protected_path_scan_passed=true"
  echo "new_public_surface=cjguiExperimentalComponentCommitApiReady"
  echo "public_surface_stability=experimental_preview"
  echo "next_route=stage893_component_commit_api_owner_local_commit_bridge_after_stage892"
  echo "stage892_component_commit_api_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage892 component commit api runtime manager suite: route_classification=component_commit_api_runtime_manager"
echo "cjgui stage892 component commit api runtime manager suite: suite_packet_path=$SUITE_PACKET"
