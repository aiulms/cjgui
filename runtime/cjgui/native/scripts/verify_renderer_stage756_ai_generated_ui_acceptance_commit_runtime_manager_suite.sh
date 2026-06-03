#!/usr/bin/env zsh
#
# Focused suite for stage756. It consumes stage755, verifies the shared
# acceptance commit runtime manager, builds runtime/cjgui, and scans stop-lines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE756_TMPDIR:-/private/tmp/cjgui-stage753-stage756/stage756}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage756-ai-generated-ui-acceptance-commit-runtime-manager-suite.packet"
STAGE755_SUITE_PACKET="${CJGUI_STAGE756_INPUT_PACKET:-${CJGUI_STAGE755_AI_GENERATED_UI_ACCEPTANCE_COMMIT_HOST_INSPECTION_PROOF_SUITE_PACKET:-/private/tmp/cjgui-stage753-stage756/stage755/stage755-ai-generated-ui-acceptance-commit-host-inspection-proof-suite.packet}}"
STAGE755_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage756_ai_generated_ui_acceptance_commit_runtime_manager_owner.sh"
OWNER_LOG="$TMP_DIR/stage756-ai-generated-ui-acceptance-commit-runtime-manager-owner.log"

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
    echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE755_SUITE_PACKET" ]] || ! grep -F "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_suite_passed=true" "$STAGE755_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE755_TMPDIR="$TMP_DIR/stage755" zsh "$STAGE755_SUITE_SCRIPT" >/dev/null
  STAGE755_SUITE_PACKET="$TMP_DIR/stage755/stage755-ai-generated-ui-acceptance-commit-host-inspection-proof-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_consumed=true" \
  "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_consumed_transitively=true" \
  "stage753_ai_generated_ui_acceptance_commit_preflight_consumed_transitively=true" \
  "stage752_ai_generated_ui_owner_acceptance_runtime_manager_consumed_transitively=true" \
  "shared_ai_generated_ui_acceptance_commit_runtime_manager_materialized=true" \
  "acceptance_commit_runtime_contract_materialized=true" \
  "acceptance_commit_execution_receipt_contract_materialized=true" \
  "cycle_order_owner_runtime_commit_snapshot_host_proof_runtime_materialized=true" \
  "future_per_demo_acceptance_commit_template_need_reduced=true" \
  "stage757_minimal_public_preview_api_first_slice_prepared=true" \
  "owner_acceptance_granted=false" \
  "acceptance_commit_committed=false" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_suite_passed=true" \
  "acceptance_commit_host_inspection_rows_materialized=true" \
  "acceptance_commit_result_surface_preview_materialized=true" \
  "acceptance_commit_render_command_refresh_receipt_materialized=true" \
  "stage756_ai_generated_ui_acceptance_commit_runtime_manager_prepared=true"; do
  require_file_fact "$STAGE755_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage753_ai_generated_ui_acceptance_commit_preflight.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage754_ai_generated_ui_acceptance_commit_rollback_snapshot.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage755_ai_generated_ui_acceptance_commit_host_inspection_proof.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage756_ai_generated_ui_acceptance_commit_runtime_manager.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: runtime package build failed" >&2
  echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage756_ai_generated_ui_acceptance_commit_runtime_manager_suite_version=1"
  echo "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_suite_packet=$STAGE755_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage753_stage756_public_foreign_scan_passed=true"
  echo "stage753_stage756_forbidden_native_render_token_scan_passed=true"
  echo "stage756_protected_path_scan_passed=true"
  echo "next_route=stage757_minimal_public_preview_api_first_slice_after_stage756"
  echo "stage756_ai_generated_ui_acceptance_commit_runtime_manager_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: route_classification=acceptance_commit_runtime_manager_ready"
echo "cjgui stage756 ai generated ui acceptance commit runtime manager suite: suite_packet_path=$SUITE_PACKET"
