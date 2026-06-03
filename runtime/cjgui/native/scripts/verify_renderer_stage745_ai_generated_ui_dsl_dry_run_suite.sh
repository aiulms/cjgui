#!/usr/bin/env zsh
#
# Focused suite for stage745. It consumes stage744, verifies AI-generated UI
# DSL dry-run ownership, builds runtime/cjgui, and scans stop-lines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE745_TMPDIR:-/private/tmp/cjgui-stage745-stage748/stage745}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage745-ai-generated-ui-dsl-dry-run-suite.packet"
STAGE744_SUITE_PACKET="${CJGUI_STAGE745_INPUT_PACKET:-${CJGUI_STAGE744_COMPONENT_API_AUTHORING_DSL_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage741-stage744/stage744/stage744-component-api-authoring-dsl-runtime-manager-suite.packet}}"
STAGE744_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage744_component_api_authoring_dsl_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage745_ai_generated_ui_dsl_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage745-ai-generated-ui-dsl-dry-run-owner.log"

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
    echo "cjgui stage745 ai generated ui dsl dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE744_SUITE_PACKET" ]] || ! grep -F "stage744_component_api_authoring_dsl_runtime_manager_suite_passed=true" "$STAGE744_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE744_TMPDIR="$TMP_DIR/stage744" zsh "$STAGE744_SUITE_SCRIPT" >/dev/null
  STAGE744_SUITE_PACKET="$TMP_DIR/stage744/stage744-component-api-authoring-dsl-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage744_component_api_authoring_dsl_runtime_manager_consumed=true" \
  "ai_generated_ui_prompt_constraint_ledger_materialized=true" \
  "ai_generated_ui_component_declaration_proposal_materialized=true" \
  "ai_generated_ui_dry_run_request_contract_materialized=true" \
  "chat_composer_ai_generated_ui_dsl_dry_run_surface_materialized=true" \
  "stage746_ai_generated_ui_owner_review_preflight_prepared=true" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage744_component_api_authoring_dsl_runtime_manager_suite_passed=true" \
  "shared_component_api_authoring_dsl_runtime_manager_materialized=true" \
  "component_api_authoring_dsl_runtime_contract_materialized=true" \
  "stage745_component_api_authoring_dsl_ai_generated_ui_dry_run_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE744_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage745_ai_generated_ui_dsl_dry_run.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage745 ai generated ui dsl dry-run suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage745 ai generated ui dsl dry-run suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage745 ai generated ui dsl dry-run suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage745 ai generated ui dsl dry-run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage745 ai generated ui dsl dry-run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage745 ai generated ui dsl dry-run suite: runtime package build failed" >&2
  echo "cjgui stage745 ai generated ui dsl dry-run suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage745_ai_generated_ui_dsl_dry_run_suite_version=1"
  echo "stage744_component_api_authoring_dsl_runtime_manager_suite_packet=$STAGE744_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage745_public_foreign_scan_passed=true"
  echo "stage745_forbidden_native_render_token_scan_passed=true"
  echo "stage745_protected_path_scan_passed=true"
  echo "next_route=stage746_ai_generated_ui_owner_review_preflight_after_stage745"
  echo "stage745_ai_generated_ui_dsl_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage745 ai generated ui dsl dry-run suite: route_classification=ai_generated_ui_dsl_dry_run_ready"
echo "cjgui stage745 ai generated ui dsl dry-run suite: suite_packet_path=$SUITE_PACKET"
