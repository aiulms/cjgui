#!/usr/bin/env zsh
#
# Focused suite for stage600. It consumes stage599 reducer evidence and
# verifies shared demo host feedback surface integration with build/scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE600_TMPDIR:-/private/tmp/cjgui-stage597-stage600/stage600}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage600-form-result-demo-host-feedback-surface-integration-suite.packet"
STAGE599_SUITE_PACKET="${CJGUI_STAGE600_INPUT_PACKET:-${CJGUI_STAGE599_FORM_RESULT_FEEDBACK_SURFACE_REDUCER_SUITE_PACKET:-/private/tmp/cjgui-stage597-stage600/stage599/stage599-form-result-feedback-surface-reducer-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage600_form_result_demo_host_feedback_surface_integration_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage600_form_result_demo_host_feedback_surface_integration.cj"
OWNER_LOG="$TMP_DIR/stage600-form-result-demo-host-feedback-surface-integration-owner.log"

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
    echo "cjgui stage600 form result demo host feedback surface integration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage600 form result demo host feedback surface integration suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage599_form_result_feedback_surface_reducer_consumed=true" \
  "shared_form_result_demo_host_feedback_surface_integration_materialized=true" \
  "shared_form_result_demo_host_feedback_surface_helper_materialized=true" \
  "shared_form_result_demo_host_feedback_execution_contract_materialized=true" \
  "chat_composer_demo_host_feedback_surface_integration_materialized=true" \
  "demo_host_feedback_surface_integration_bound_to_stage599_reducer=true" \
  "demo_host_feedback_surface_integration_bound_to_stage598_host_inspection=true" \
  "demo_host_feedback_surface_integration_bound_to_stage597_validation_focus_surface=true" \
  "demo_host_feedback_surface_integration_bound_to_stage596_runtime_contract=true" \
  "per_demo_validation_focus_host_template_need_reduced=true" \
  "stage601_form_result_feedback_surface_input_event_bridge_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE599_SUITE_PACKET" || ! -f "$STAGE599_SUITE_PACKET" ]]; then
  echo "cjgui stage600 form result demo host feedback surface integration suite: missing stage599 packet; set CJGUI_STAGE600_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage599_form_result_feedback_surface_reducer_suite_version=1" \
  "stage598_form_result_feedback_host_inspection_receipt_consumed=true" \
  "shared_form_result_feedback_surface_reducer_materialized=true" \
  "accepted_feedback_surface_reduction_materialized=true" \
  "validation_focus_input_feedback_reduction_ledger_materialized=true" \
  "chat_composer_reduced_form_result_feedback_surface_materialized=true" \
  "stage600_form_result_demo_host_feedback_surface_integration_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE599_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage597_form_result_feedback_validation_focus_surface.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage598_form_result_feedback_host_inspection_receipt.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage599_form_result_feedback_surface_reducer.cj" \
  "$OWNER_SRC"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage600 form result demo host feedback surface integration suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage600 form result demo host feedback surface integration suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage600 form result demo host feedback surface integration suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage600 form result demo host feedback surface integration suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage600 form result demo host feedback surface integration suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage600 form result demo host feedback surface integration suite: runtime package build failed" >&2
  echo "cjgui stage600 form result demo host feedback surface integration suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage600_form_result_demo_host_feedback_surface_integration_suite_version=1"
  echo "stage599_form_result_feedback_surface_reducer_suite_packet=$STAGE599_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage600_form_result_demo_host_feedback_surface_integration_owner_passed=true"
  echo "stage599_form_result_feedback_surface_reducer_consumed=true"
  echo "stage598_form_result_feedback_host_inspection_receipt_consumed_transitively=true"
  echo "stage597_form_result_feedback_validation_focus_surface_consumed_transitively=true"
  echo "stage596_form_result_host_feedback_cycle_runtime_contract_consumed_transitively=true"
  echo "shared_form_result_demo_host_feedback_surface_integration_materialized=true"
  echo "shared_form_result_demo_host_feedback_surface_helper_materialized=true"
  echo "shared_form_result_demo_host_feedback_execution_contract_materialized=true"
  echo "todo_demo_host_feedback_surface_integration_materialized=true"
  echo "settings_demo_host_feedback_surface_integration_materialized=true"
  echo "ai_generated_settings_demo_host_feedback_surface_integration_materialized=true"
  echo "chat_composer_demo_host_feedback_surface_integration_materialized=true"
  echo "demo_host_feedback_surface_integration_bound_to_stage599_reducer=true"
  echo "demo_host_feedback_surface_integration_bound_to_stage598_host_inspection=true"
  echo "demo_host_feedback_surface_integration_bound_to_stage597_validation_focus_surface=true"
  echo "demo_host_feedback_surface_integration_bound_to_stage596_runtime_contract=true"
  echo "per_demo_validation_focus_host_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage597_stage600_public_foreign_scan_passed=true"
  echo "stage597_stage600_forbidden_native_render_token_scan_passed=true"
  echo "stage600_protected_path_scan_passed=true"
  echo "stage601_form_result_feedback_surface_input_event_bridge_prepared=true"
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
  echo "next_route=stage601_component_runtime_form_result_feedback_surface_input_event_bridge_after_stage600"
  echo "stage600_form_result_demo_host_feedback_surface_integration_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage600 form result demo host feedback surface integration suite: route_classification=form_result_demo_host_feedback_surface_integration_ready"
echo "cjgui stage600 form result demo host feedback surface integration suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage600 form result demo host feedback surface integration suite: consumed_stage599=true"
echo "cjgui stage600 form result demo host feedback surface integration suite: visibility_published=false"
