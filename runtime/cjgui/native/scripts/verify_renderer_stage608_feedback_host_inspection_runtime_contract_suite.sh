#!/usr/bin/env zsh
#
# Focused suite for stage608. It consumes stage607 demo surfaces and verifies
# the shared feedback host inspection runtime contract with build/scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE608_TMPDIR:-/private/tmp/cjgui-stage605-stage608/stage608}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage608-feedback-host-inspection-runtime-contract-suite.packet"
STAGE607_SUITE_PACKET="${CJGUI_STAGE608_INPUT_PACKET:-${CJGUI_STAGE607_FEEDBACK_HOST_INSPECTION_DEMO_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage605-stage608/stage607/stage607-feedback-host-inspection-demo-surface-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage608_feedback_host_inspection_runtime_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage608-feedback-host-inspection-runtime-contract-owner.log"

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
    echo "cjgui stage608 feedback host inspection runtime contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage608 feedback host inspection runtime contract suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage607_feedback_host_inspection_demo_surface_consumed=true" \
  "shared_feedback_host_inspection_runtime_contract_materialized=true" \
  "shared_feedback_host_inspection_runtime_helper_materialized=true" \
  "shared_feedback_host_inspection_execution_contract_materialized=true" \
  "chat_composer_checkable_feedback_host_inspection_runtime_surface_materialized=true" \
  "per_demo_feedback_host_inspection_template_need_reduced=true" \
  "stage609_feedback_host_inspection_input_state_bridge_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE607_SUITE_PACKET" || ! -f "$STAGE607_SUITE_PACKET" ]]; then
  echo "cjgui stage608 feedback host inspection runtime contract suite: missing stage607 packet; set CJGUI_STAGE608_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage607_feedback_host_inspection_demo_surface_suite_version=1" \
  "stage606_feedback_host_input_visual_execution_receipt_consumed=true" \
  "stage605_form_result_feedback_host_input_layout_focus_inspection_consumed_transitively=true" \
  "shared_feedback_host_inspection_demo_surface_materialized=true" \
  "stage608_feedback_host_inspection_runtime_contract_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE607_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage605_form_result_feedback_host_input_layout_focus_inspection.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage606_feedback_host_input_visual_execution_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage607_feedback_host_inspection_demo_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage608_feedback_host_inspection_runtime_contract.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage608 feedback host inspection runtime contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage608 feedback host inspection runtime contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage608 feedback host inspection runtime contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage608 feedback host inspection runtime contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage608 feedback host inspection runtime contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage608 feedback host inspection runtime contract suite: runtime package build failed" >&2
  echo "cjgui stage608 feedback host inspection runtime contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage608_feedback_host_inspection_runtime_contract_suite_version=1"
  echo "stage607_feedback_host_inspection_demo_surface_suite_packet=$STAGE607_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage608_feedback_host_inspection_runtime_contract_owner_passed=true"
  echo "stage607_feedback_host_inspection_demo_surface_consumed=true"
  echo "stage606_feedback_host_input_visual_execution_receipt_consumed_transitively=true"
  echo "stage605_form_result_feedback_host_input_layout_focus_inspection_consumed_transitively=true"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_consumed_transitively=true"
  echo "shared_feedback_host_inspection_runtime_contract_materialized=true"
  echo "shared_feedback_host_inspection_runtime_helper_materialized=true"
  echo "shared_feedback_host_inspection_execution_contract_materialized=true"
  echo "todo_checkable_feedback_host_inspection_runtime_surface_materialized=true"
  echo "settings_checkable_feedback_host_inspection_runtime_surface_materialized=true"
  echo "ai_generated_settings_checkable_feedback_host_inspection_runtime_surface_materialized=true"
  echo "chat_composer_checkable_feedback_host_inspection_runtime_surface_materialized=true"
  echo "runtime_contract_bound_to_stage607_demo_surfaces=true"
  echo "runtime_contract_bound_to_stage606_visual_execution_receipts=true"
  echo "runtime_contract_bound_to_stage605_layout_focus_inspection=true"
  echo "per_demo_feedback_host_inspection_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage605_stage608_public_foreign_scan_passed=true"
  echo "stage605_stage608_forbidden_native_render_token_scan_passed=true"
  echo "stage608_protected_path_scan_passed=true"
  echo "stage609_feedback_host_inspection_input_state_bridge_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_enabled=false"
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
  echo "next_route=stage609_component_runtime_feedback_host_inspection_input_state_bridge_after_stage608"
  echo "stage608_feedback_host_inspection_runtime_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage608 feedback host inspection runtime contract suite: route_classification=feedback_host_inspection_runtime_contract_ready"
echo "cjgui stage608 feedback host inspection runtime contract suite: suite_packet_path=$SUITE_PACKET"
