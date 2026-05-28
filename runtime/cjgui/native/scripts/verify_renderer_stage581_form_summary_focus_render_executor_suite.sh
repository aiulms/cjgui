#!/usr/bin/env zsh
#
# Focused suite for stage581. It consumes stage580 layout/validation surfaces
# and verifies a shared form summary/focus/render dry-run executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE581_TMPDIR:-/private/tmp/cjgui-stage580-stage582/stage581}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage581-form-summary-focus-render-executor-suite.packet"
STAGE580_SUITE_PACKET="${CJGUI_STAGE581_INPUT_PACKET:-${CJGUI_STAGE580_FORM_FIELD_LAYOUT_VALIDATION_INTEGRATION_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage581_form_summary_focus_render_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage581_form_summary_focus_render_executor.cj"
OWNER_LOG="$TMP_DIR/stage581-form-summary-focus-render-executor-owner.log"

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
    echo "cjgui stage581 form summary/focus/render executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage581 form summary/focus/render executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage581 form summary/focus/render executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage581 form summary/focus/render executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage581 form summary/focus/render executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage580_form_field_layout_validation_integration_consumed=true" \
  "shared_form_summary_focus_render_executor_materialized=true" \
  "form_validation_summary_ledger_materialized=true" \
  "first_invalid_field_focus_target_ledger_materialized=true" \
  "form_group_render_command_refresh_ledger_materialized=true" \
  "form_rollback_preview_ledger_materialized=true" \
  "todo_form_summary_receipt_materialized=true" \
  "settings_form_summary_receipt_materialized=true" \
  "ai_generated_settings_form_summary_receipt_materialized=true" \
  "chat_composer_form_summary_receipt_materialized=true" \
  "form_summary_executor_bound_to_stage580_layout_validation_surfaces=true" \
  "form_summary_executor_bound_to_stage579_submission_surfaces=true" \
  "form_summary_executor_non_dispatching=true" \
  "form_summary_state_dry_run_only=true" \
  "stage582_form_demo_runtime_surface_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE580_SUITE_PACKET" || ! -f "$STAGE580_SUITE_PACKET" ]]; then
  echo "cjgui stage581 form summary/focus/render executor suite: missing stage580 packet; set CJGUI_STAGE581_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage580_form_field_layout_validation_integration_suite_version=1" \
  "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed=true" \
  "shared_form_field_layout_validation_integration_materialized=true" \
  "form_field_validation_message_layout_slot_ledger_materialized=true" \
  "form_field_invalid_style_token_ledger_materialized=true" \
  "form_field_submit_affordance_layout_refresh_ledger_materialized=true" \
  "chat_composer_form_field_layout_validation_surface_materialized=true" \
  "stage581_form_summary_focus_render_executor_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE580_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage581 form summary/focus/render executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage581 form summary/focus/render executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage581 form summary/focus/render executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage581 form summary/focus/render executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage581 form summary/focus/render executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage581 form summary/focus/render executor suite: runtime package build failed" >&2
  echo "cjgui stage581 form summary/focus/render executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage581_form_summary_focus_render_executor_suite_version=1"
  echo "stage580_form_field_layout_validation_integration_suite_packet=$STAGE580_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage581_form_summary_focus_render_executor_owner_passed=true"
  echo "stage580_form_field_layout_validation_integration_consumed=true"
  echo "stage579_component_runtime_form_field_submission_demo_surface_contract_consumed_transitively=true"
  echo "shared_form_summary_focus_render_executor_materialized=true"
  echo "form_validation_summary_ledger_materialized=true"
  echo "first_invalid_field_focus_target_ledger_materialized=true"
  echo "form_group_render_command_refresh_ledger_materialized=true"
  echo "form_rollback_preview_ledger_materialized=true"
  echo "todo_form_summary_receipt_materialized=true"
  echo "settings_form_summary_receipt_materialized=true"
  echo "ai_generated_settings_form_summary_receipt_materialized=true"
  echo "chat_composer_form_summary_receipt_materialized=true"
  echo "form_summary_executor_bound_to_stage580_layout_validation_surfaces=true"
  echo "form_summary_executor_bound_to_stage579_submission_surfaces=true"
  echo "form_summary_executor_non_dispatching=true"
  echo "form_summary_state_dry_run_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage581_public_foreign_scan_passed=true"
  echo "stage581_forbidden_native_render_token_scan_passed=true"
  echo "stage581_protected_path_scan_passed=true"
  echo "stage582_form_demo_runtime_surface_contract_prepared=true"
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
  echo "next_route=stage582_form_demo_runtime_surface_contract_after_stage581"
  echo "stage581_form_summary_focus_render_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage581 form summary/focus/render executor suite: route_classification=form_summary_focus_render_executor_ready"
echo "cjgui stage581 form summary/focus/render executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage581 form summary/focus/render executor suite: consumed_stage580=true"
echo "cjgui stage581 form summary/focus/render executor suite: state_update_committed=false"
