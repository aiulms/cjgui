#!/usr/bin/env zsh
#
# Focused suite for stage760. It consumes stage759, builds runtime/cjgui, and
# records the public declaration scan for the minimal preview component API.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE760_TMPDIR:-/private/tmp/cjgui-stage757-stage760/stage760}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage760-minimal-public-preview-api-public-scan-contract-suite.packet"
STAGE759_SUITE_PACKET="${CJGUI_STAGE760_INPUT_PACKET:-${CJGUI_STAGE759_MINIMAL_PUBLIC_PREVIEW_API_DEMO_CONSUMPTION_SUITE_PACKET:-/private/tmp/cjgui-stage757-stage760/stage759/stage759-minimal-public-preview-api-demo-consumption-suite.packet}}"
STAGE759_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage759_minimal_public_preview_api_demo_consumption_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage760_minimal_public_preview_api_public_scan_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage760-minimal-public-preview-api-public-scan-contract-owner.log"

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
    echo "cjgui stage760 minimal public preview api public scan contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE759_SUITE_PACKET" ]] || ! grep -F "stage759_minimal_public_preview_api_demo_consumption_suite_passed=true" "$STAGE759_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE759_TMPDIR="$TMP_DIR/stage759" zsh "$STAGE759_SUITE_SCRIPT" >/dev/null
  STAGE759_SUITE_PACKET="$TMP_DIR/stage759/stage759-minimal-public-preview-api-demo-consumption-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage759_minimal_public_preview_api_demo_consumption_consumed=true" \
  "public_declaration_scan_receipt_materialized=true" \
  "public_surface_cjguiExperimentalComponentPreviewApiReady_listed=true" \
  "compatibility_rollback_note_materialized=true" \
  "future_public_preview_api_template_need_reduced=true" \
  "public_component_api_added=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "stage761_preview_component_api_layout_style_consumption_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage759_minimal_public_preview_api_demo_consumption_suite_passed=true" \
  "todo_public_preview_api_demo_surface_materialized=true" \
  "settings_public_preview_api_demo_surface_materialized=true" \
  "public_component_api_added=true" \
  "stable_public_api_added=false"; do
  require_file_fact "$STAGE759_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage757_minimal_public_preview_api_descriptor.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage758_minimal_public_preview_api_declaration.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage759_minimal_public_preview_api_demo_consumption.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage760_minimal_public_preview_api_public_scan_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage760 minimal public preview api public scan contract suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage760 minimal public preview api public scan contract suite: disallowed public type or foreign declaration found in $src" >&2
    exit 11
  fi
  if [[ "$src" != *"stage758_minimal_public_preview_api_declaration.cj" ]] && sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'public[[:space:]]+func' >/dev/null 2>&1; then
    echo "cjgui stage760 minimal public preview api public scan contract suite: unexpected public func in $src" >&2
    exit 12
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage760 minimal public preview api public scan contract suite: forbidden native/render token found in $src" >&2
    exit 13
  fi
done

if ! sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$ROOT_DIR/src/runtime_renderer_stage758_minimal_public_preview_api_declaration.cj" \
  | grep -E '^public[[:space:]]+func[[:space:]]+cjguiExperimentalComponentPreviewApiReady\(\):[[:space:]]+Bool' >/dev/null 2>&1; then
  echo "cjgui stage760 minimal public preview api public scan contract suite: exact public preview function missing" >&2
  exit 14
fi

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage760 minimal public preview api public scan contract suite: protected production bridge/state path modified" >&2
  exit 15
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage760 minimal public preview api public scan contract suite: cjpm unavailable" >&2
  exit 16
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage760 minimal public preview api public scan contract suite: runtime package build failed" >&2
  echo "cjgui stage760 minimal public preview api public scan contract suite: log=$BUILD_LOG" >&2
  exit 17
fi

{
  echo "stage760_minimal_public_preview_api_public_scan_contract_suite_version=1"
  echo "stage759_minimal_public_preview_api_demo_consumption_suite_packet=$STAGE759_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage757_stage760_public_declaration_scan_passed=true"
  echo "stage757_stage760_forbidden_native_render_token_scan_passed=true"
  echo "stage760_protected_path_scan_passed=true"
  echo "new_public_surface=cjguiExperimentalComponentPreviewApiReady"
  echo "new_public_surface_stability=experimental_preview"
  echo "next_route=stage761_preview_component_api_layout_style_consumption_after_stage760"
  echo "stage760_minimal_public_preview_api_public_scan_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage760 minimal public preview api public scan contract suite: route_classification=public_preview_api_first_slice_ready"
echo "cjgui stage760 minimal public preview api public scan contract suite: suite_packet_path=$SUITE_PACKET"
