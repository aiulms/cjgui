#!/usr/bin/env zsh
#
# Focused suite for stage765. It consumes stage764 and records preview component
# API commit preflight evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE765_TMPDIR:-/private/tmp/cjgui-stage765-stage768/stage765}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage765-preview-component-api-commit-preflight-suite.packet"
STAGE764_SUITE_PACKET="${CJGUI_STAGE765_INPUT_PACKET:-${CJGUI_STAGE764_PREVIEW_COMPONENT_API_VISUAL_RESOLVER_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage761-stage764/stage764/stage764-preview-component-api-visual-resolver-runtime-manager-suite.packet}}"
STAGE764_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage764_preview_component_api_visual_resolver_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage765_preview_component_api_commit_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage765-preview-component-api-commit-preflight-owner.log"

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
    echo "cjgui stage765 preview component api commit preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE764_SUITE_PACKET" ]] || ! grep -F "stage764_preview_component_api_visual_resolver_runtime_manager_suite_passed=true" "$STAGE764_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE764_TMPDIR="$TMP_DIR/stage764" zsh "$STAGE764_SUITE_SCRIPT" >/dev/null
  STAGE764_SUITE_PACKET="$TMP_DIR/stage764/stage764-preview-component-api-visual-resolver-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage764_preview_component_api_visual_resolver_runtime_manager_consumed=true" \
  "shared_preview_component_api_commit_preflight_materialized=true" \
  "preview_component_api_commit_candidate_ledger_materialized=true" \
  "preview_component_api_compatibility_commit_gate_materialized=true" \
  "visual_resolver_result_to_commit_plan_bridge_materialized=true" \
  "chat_composer_preview_component_api_commit_preflight_surface_materialized=true" \
  "stage766_preview_component_api_commit_rollback_snapshot_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage764_preview_component_api_visual_resolver_runtime_manager_suite_passed=true" \
  "shared_preview_component_api_visual_resolver_runtime_manager_materialized=true" \
  "preview_component_api_visual_resolver_runtime_contract_materialized=true"; do
  require_file_fact "$STAGE764_SUITE_PACKET" "$fact"
done

for src in "$ROOT_DIR/src/runtime_renderer_stage765_preview_component_api_commit_preflight.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage765 preview component api commit preflight suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage765 preview component api commit preflight suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage765 preview component api commit preflight suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage765.*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage765 preview component api commit preflight suite: unexpected stage765 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage765 preview component api commit preflight suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage765 preview component api commit preflight suite: cjpm unavailable" >&2
  exit 15
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage765 preview component api commit preflight suite: runtime package build failed" >&2
  echo "cjgui stage765 preview component api commit preflight suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage765_preview_component_api_commit_preflight_suite_version=1"
  echo "stage764_preview_component_api_visual_resolver_runtime_manager_suite_packet=$STAGE764_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage765_public_declaration_scan_passed=true"
  echo "stage765_forbidden_native_render_token_scan_passed=true"
  echo "stage765_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage766_preview_component_api_commit_rollback_snapshot_after_stage765"
  echo "stage765_preview_component_api_commit_preflight_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage765 preview component api commit preflight suite: route_classification=public_preview_api_commit_preflight"
echo "cjgui stage765 preview component api commit preflight suite: suite_packet_path=$SUITE_PACKET"
