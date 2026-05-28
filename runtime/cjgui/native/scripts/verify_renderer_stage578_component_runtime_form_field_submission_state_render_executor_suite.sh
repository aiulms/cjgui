#!/usr/bin/env zsh
#
# Focused suite for stage578. It consumes stage577 submit action intents and
# verifies a shared non-dispatching submission state/render dry-run executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE578_TMPDIR:-/private/tmp/cjgui-stage577-stage579/stage578}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage578-component-runtime-form-field-submission-state-render-executor-suite.packet"
STAGE577_SUITE_PACKET="${CJGUI_STAGE578_INPUT_PACKET:-${CJGUI_STAGE577_COMPONENT_RUNTIME_FORM_FIELD_SUBMIT_ACTION_ADAPTER_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage578_component_runtime_form_field_submission_state_render_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage578_component_runtime_form_field_submission_state_render_executor.cj"
OWNER_LOG="$TMP_DIR/stage578-component-runtime-form-field-submission-state-render-executor-owner.log"

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
    echo "cjgui stage578 component runtime form-field submission state/render executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage577_component_runtime_form_field_submit_action_adapter_consumed=true" \
  "shared_form_field_submission_state_render_executor_materialized=true" \
  "form_field_submission_state_delta_dry_run_ledger_materialized=true" \
  "form_field_submission_validation_result_ledger_materialized=true" \
  "form_field_submission_render_command_refresh_ledger_materialized=true" \
  "todo_form_field_submission_receipt_materialized=true" \
  "settings_form_field_submission_receipt_materialized=true" \
  "ai_generated_settings_form_field_submission_receipt_materialized=true" \
  "chat_composer_form_field_submission_receipt_materialized=true" \
  "form_field_submission_executor_bound_to_stage577_action_intents=true" \
  "form_field_submission_executor_bound_to_stage576_runtime_surfaces=true" \
  "form_field_submission_executor_non_dispatching=true" \
  "form_field_submission_state_dry_run_only=true" \
  "stage579_component_runtime_form_field_submission_demo_surface_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE577_SUITE_PACKET" || ! -f "$STAGE577_SUITE_PACKET" ]]; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: missing stage577 packet; set CJGUI_STAGE578_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage577_component_runtime_form_field_submit_action_adapter_suite_version=1" \
  "stage576_component_runtime_form_field_demo_runtime_contract_consumed=true" \
  "shared_form_field_submit_action_adapter_materialized=true" \
  "form_field_submit_intent_ledger_materialized=true" \
  "form_field_cancel_intent_ledger_materialized=true" \
  "form_field_validate_on_submit_intent_ledger_materialized=true" \
  "form_field_submit_adapter_non_dispatching=true" \
  "stage578_component_runtime_form_field_submission_state_render_executor_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE577_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: runtime package build failed" >&2
  echo "cjgui stage578 component runtime form-field submission state/render executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage578_component_runtime_form_field_submission_state_render_executor_suite_version=1"
  echo "stage577_component_runtime_form_field_submit_action_adapter_suite_packet=$STAGE577_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage578_component_runtime_form_field_submission_state_render_executor_owner_passed=true"
  echo "stage577_component_runtime_form_field_submit_action_adapter_consumed=true"
  echo "stage576_component_runtime_form_field_demo_runtime_contract_consumed_transitively=true"
  echo "shared_form_field_submission_state_render_executor_materialized=true"
  echo "form_field_submission_state_delta_dry_run_ledger_materialized=true"
  echo "form_field_submission_validation_result_ledger_materialized=true"
  echo "form_field_submission_render_command_refresh_ledger_materialized=true"
  echo "todo_form_field_submission_receipt_materialized=true"
  echo "settings_form_field_submission_receipt_materialized=true"
  echo "ai_generated_settings_form_field_submission_receipt_materialized=true"
  echo "chat_composer_form_field_submission_receipt_materialized=true"
  echo "form_field_submission_executor_bound_to_stage577_action_intents=true"
  echo "form_field_submission_executor_bound_to_stage576_runtime_surfaces=true"
  echo "form_field_submission_executor_non_dispatching=true"
  echo "form_field_submission_state_dry_run_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage578_public_foreign_scan_passed=true"
  echo "stage578_forbidden_native_render_token_scan_passed=true"
  echo "stage578_protected_path_scan_passed=true"
  echo "stage579_component_runtime_form_field_submission_demo_surface_contract_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
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
  echo "next_route=stage579_component_runtime_form_field_submission_demo_surface_contract_after_stage578"
  echo "stage578_component_runtime_form_field_submission_state_render_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage578 component runtime form-field submission state/render executor suite: route_classification=form_field_submission_state_render_executor_ready"
echo "cjgui stage578 component runtime form-field submission state/render executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage578 component runtime form-field submission state/render executor suite: consumed_stage577=true"
echo "cjgui stage578 component runtime form-field submission state/render executor suite: state_update_committed=false"
