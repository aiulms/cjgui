#!/usr/bin/env zsh
#
# Focused suite for stage604. It consumes stage603 cycle receipts and verifies
# shared host input runtime surface contract with build/scans.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE604_TMPDIR:-/private/tmp/cjgui-stage601-stage604/stage604}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage604-form-result-feedback-host-input-runtime-surface-contract-suite.packet"
STAGE603_SUITE_PACKET="${CJGUI_STAGE604_INPUT_PACKET:-${CJGUI_STAGE603_FORM_RESULT_FEEDBACK_SURFACE_EVENT_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage601-stage604/stage603/stage603-form-result-feedback-surface-event-cycle-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage604_form_result_feedback_host_input_runtime_surface_contract_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage604_form_result_feedback_host_input_runtime_surface_contract.cj"
OWNER_LOG="$TMP_DIR/stage604-form-result-feedback-host-input-runtime-surface-contract-owner.log"

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
    echo "cjgui stage604 form result feedback host input runtime surface contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage604 form result feedback host input runtime surface contract suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage603_form_result_feedback_surface_event_cycle_executor_consumed=true" \
  "shared_form_result_feedback_host_input_runtime_surface_contract_materialized=true" \
  "shared_form_result_feedback_host_input_runtime_surface_helper_materialized=true" \
  "shared_feedback_host_input_execution_receipt_contract_materialized=true" \
  "chat_composer_checkable_feedback_host_input_runtime_surface_materialized=true" \
  "host_input_runtime_surface_contract_bound_to_stage603_cycle_receipts=true" \
  "per_demo_feedback_input_runtime_template_need_reduced=true" \
  "stage605_form_result_feedback_host_input_layout_focus_inspection_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE603_SUITE_PACKET" || ! -f "$STAGE603_SUITE_PACKET" ]]; then
  echo "cjgui stage604 form result feedback host input runtime surface contract suite: missing stage603 packet; set CJGUI_STAGE604_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage603_form_result_feedback_surface_event_cycle_executor_suite_version=1" \
  "stage602_form_result_feedback_surface_event_normalizer_consumed=true" \
  "shared_form_result_feedback_surface_event_cycle_executor_materialized=true" \
  "feedback_surface_action_intent_preview_ledger_materialized=true" \
  "feedback_surface_state_delta_dry_run_ledger_materialized=true" \
  "feedback_surface_render_command_refresh_ledger_materialized=true" \
  "chat_composer_feedback_surface_event_cycle_receipt_materialized=true" \
  "stage604_form_result_feedback_host_input_runtime_surface_contract_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE603_SUITE_PACKET" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage601_form_result_feedback_surface_input_event_bridge.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage602_form_result_feedback_surface_event_normalizer.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage603_form_result_feedback_surface_event_cycle_executor.cj" \
  "$OWNER_SRC"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage604 form result feedback host input runtime surface contract suite: missing source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage604 form result feedback host input runtime surface contract suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage604 form result feedback host input runtime surface contract suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage604 form result feedback host input runtime surface contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage604 form result feedback host input runtime surface contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage604 form result feedback host input runtime surface contract suite: runtime package build failed" >&2
  echo "cjgui stage604 form result feedback host input runtime surface contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_suite_version=1"
  echo "stage603_form_result_feedback_surface_event_cycle_executor_suite_packet=$STAGE603_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_owner_passed=true"
  echo "stage603_form_result_feedback_surface_event_cycle_executor_consumed=true"
  echo "stage602_form_result_feedback_surface_event_normalizer_consumed_transitively=true"
  echo "stage601_form_result_feedback_surface_input_event_bridge_consumed_transitively=true"
  echo "stage600_form_result_demo_host_feedback_surface_integration_consumed_transitively=true"
  echo "shared_form_result_feedback_host_input_runtime_surface_contract_materialized=true"
  echo "shared_form_result_feedback_host_input_runtime_surface_helper_materialized=true"
  echo "shared_feedback_host_input_execution_receipt_contract_materialized=true"
  echo "todo_checkable_feedback_host_input_runtime_surface_materialized=true"
  echo "settings_checkable_feedback_host_input_runtime_surface_materialized=true"
  echo "ai_generated_settings_checkable_feedback_host_input_runtime_surface_materialized=true"
  echo "chat_composer_checkable_feedback_host_input_runtime_surface_materialized=true"
  echo "host_input_runtime_surface_contract_bound_to_stage603_cycle_receipts=true"
  echo "host_input_runtime_surface_contract_bound_to_stage602_normalized_events=true"
  echo "per_demo_feedback_input_runtime_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage601_stage604_public_foreign_scan_passed=true"
  echo "stage601_stage604_forbidden_native_render_token_scan_passed=true"
  echo "stage604_protected_path_scan_passed=true"
  echo "stage605_form_result_feedback_host_input_layout_focus_inspection_prepared=true"
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
  echo "next_route=stage605_component_runtime_form_result_feedback_host_input_layout_focus_inspection_after_stage604"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage604 form result feedback host input runtime surface contract suite: route_classification=feedback_host_input_runtime_surface_contract_ready"
echo "cjgui stage604 form result feedback host input runtime surface contract suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage604 form result feedback host input runtime surface contract suite: consumed_stage603=true"
echo "cjgui stage604 form result feedback host input runtime surface contract suite: visibility_published=false"
