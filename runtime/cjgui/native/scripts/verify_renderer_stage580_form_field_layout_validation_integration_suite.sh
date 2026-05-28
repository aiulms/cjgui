#!/usr/bin/env zsh
#
# Focused suite for stage580. It consumes stage579 submission demo surfaces and
# verifies shared form-field layout/validation integration surfaces across demos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE580_TMPDIR:-/private/tmp/cjgui-stage580-stage582/stage580}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage580-form-field-layout-validation-integration-suite.packet"
STAGE579_SUITE_PACKET="${CJGUI_STAGE580_INPUT_PACKET:-${CJGUI_STAGE579_FORM_FIELD_SUBMISSION_DEMO_SURFACE_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage580_form_field_layout_validation_integration_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage580_form_field_layout_validation_integration.cj"
OWNER_LOG="$TMP_DIR/stage580-form-field-layout-validation-integration-owner.log"

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
    echo "cjgui stage580 form-field layout/validation integration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage580 form-field layout/validation integration suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage580 form-field layout/validation integration suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage580 form-field layout/validation integration suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage580 form-field layout/validation integration suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed=true" \
  "shared_form_field_layout_validation_integration_materialized=true" \
  "form_field_validation_message_layout_slot_ledger_materialized=true" \
  "form_field_invalid_style_token_ledger_materialized=true" \
  "form_field_submit_affordance_layout_refresh_ledger_materialized=true" \
  "todo_form_field_layout_validation_surface_materialized=true" \
  "settings_form_field_layout_validation_surface_materialized=true" \
  "ai_generated_settings_form_field_layout_validation_surface_materialized=true" \
  "chat_composer_form_field_layout_validation_surface_materialized=true" \
  "form_field_layout_validation_bound_to_stage579_submission_surfaces=true" \
  "form_field_layout_validation_bound_to_stage578_submission_receipts=true" \
  "form_field_layout_validation_owner_local=true" \
  "stage581_form_summary_focus_render_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE579_SUITE_PACKET" || ! -f "$STAGE579_SUITE_PACKET" ]]; then
  echo "cjgui stage580 form-field layout/validation integration suite: missing stage579 packet; set CJGUI_STAGE580_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage579_component_runtime_form_field_submission_demo_surface_contract_suite_version=1" \
  "stage578_component_runtime_form_field_submission_state_render_executor_consumed=true" \
  "shared_form_field_submission_demo_surface_contract_materialized=true" \
  "shared_form_field_submission_demo_surface_helper_materialized=true" \
  "todo_checkable_submission_demo_surface_materialized=true" \
  "settings_checkable_submission_demo_surface_materialized=true" \
  "ai_generated_settings_checkable_submission_demo_surface_materialized=true" \
  "chat_composer_checkable_submission_demo_surface_materialized=true" \
  "form_field_submission_demo_surface_bound_to_stage578_receipts=true" \
  "stage580_component_runtime_form_field_layout_validation_integration_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE579_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage580 form-field layout/validation integration suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage580 form-field layout/validation integration suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage580 form-field layout/validation integration suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage580 form-field layout/validation integration suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage580 form-field layout/validation integration suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage580 form-field layout/validation integration suite: runtime package build failed" >&2
  echo "cjgui stage580 form-field layout/validation integration suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage580_form_field_layout_validation_integration_suite_version=1"
  echo "stage579_component_runtime_form_field_submission_demo_surface_contract_suite_packet=$STAGE579_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage580_form_field_layout_validation_integration_owner_passed=true"
  echo "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed=true"
  echo "stage578_component_runtime_form_field_submission_state_render_executor_consumed_transitively=true"
  echo "shared_form_field_layout_validation_integration_materialized=true"
  echo "form_field_validation_message_layout_slot_ledger_materialized=true"
  echo "form_field_invalid_style_token_ledger_materialized=true"
  echo "form_field_submit_affordance_layout_refresh_ledger_materialized=true"
  echo "todo_form_field_layout_validation_surface_materialized=true"
  echo "settings_form_field_layout_validation_surface_materialized=true"
  echo "ai_generated_settings_form_field_layout_validation_surface_materialized=true"
  echo "chat_composer_form_field_layout_validation_surface_materialized=true"
  echo "form_field_layout_validation_bound_to_stage579_submission_surfaces=true"
  echo "form_field_layout_validation_bound_to_stage578_submission_receipts=true"
  echo "runtime_package_build_passed=true"
  echo "stage580_public_foreign_scan_passed=true"
  echo "stage580_forbidden_native_render_token_scan_passed=true"
  echo "stage580_protected_path_scan_passed=true"
  echo "stage581_form_summary_focus_render_executor_prepared=true"
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
  echo "next_route=stage581_form_summary_focus_render_executor_after_stage580"
  echo "stage580_form_field_layout_validation_integration_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage580 form-field layout/validation integration suite: route_classification=form_field_layout_validation_integration_ready"
echo "cjgui stage580 form-field layout/validation integration suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage580 form-field layout/validation integration suite: consumed_stage579=true"
echo "cjgui stage580 form-field layout/validation integration suite: layout_engine_enabled=false"
