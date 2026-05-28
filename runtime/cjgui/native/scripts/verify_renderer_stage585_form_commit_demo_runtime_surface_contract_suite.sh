#!/usr/bin/env zsh
#
# Focused suite for stage585. It consumes stage584 form commit cycle receipts
# and verifies one shared checkable form commit demo runtime surface contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE585_TMPDIR:-/private/tmp/cjgui-stage583-stage585/stage585}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage585-form-commit-demo-runtime-surface-contract-suite.packet"
STAGE584_SUITE_PACKET="${CJGUI_STAGE585_INPUT_PACKET:-${CJGUI_STAGE584_FORM_COMMIT_CYCLE_EXECUTOR_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage585_form_commit_demo_runtime_surface_contract_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage585_form_commit_demo_runtime_surface_contract.cj"
OWNER_LOG="$TMP_DIR/stage585-form-commit-demo-runtime-surface-contract-owner.log"

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
    echo "cjgui stage585 form commit demo runtime surface contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage585 form commit demo runtime surface contract suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage584_form_commit_cycle_executor_consumed=true" \
  "shared_form_commit_demo_runtime_surface_contract_materialized=true" \
  "shared_form_commit_demo_runtime_surface_helper_materialized=true" \
  "shared_form_commit_execution_receipt_contract_materialized=true" \
  "todo_checkable_form_commit_runtime_surface_materialized=true" \
  "settings_checkable_form_commit_runtime_surface_materialized=true" \
  "ai_generated_settings_checkable_form_commit_runtime_surface_materialized=true" \
  "chat_composer_checkable_form_commit_runtime_surface_materialized=true" \
  "form_commit_demo_runtime_surface_bound_to_stage584_cycle_receipts=true" \
  "form_commit_demo_runtime_surface_bound_to_stage583_commit_preview=true" \
  "form_commit_demo_runtime_surface_bound_to_stage582_runtime_surfaces=true" \
  "per_demo_form_commit_runtime_template_need_reduced=true" \
  "stage586_component_runtime_form_commit_result_surface_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE584_SUITE_PACKET" || ! -f "$STAGE584_SUITE_PACKET" ]]; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: missing stage584 packet; set CJGUI_STAGE585_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage584_form_commit_cycle_executor_suite_version=1" \
  "stage583_form_input_event_commit_preview_consumed=true" \
  "shared_form_commit_cycle_executor_materialized=true" \
  "form_commit_action_intent_ledger_materialized=true" \
  "form_commit_state_delta_dry_run_ledger_materialized=true" \
  "form_commit_validation_refresh_ledger_materialized=true" \
  "form_commit_render_command_refresh_ledger_materialized=true" \
  "chat_composer_form_commit_cycle_receipt_materialized=true" \
  "stage585_form_commit_demo_runtime_surface_contract_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE584_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage585 form commit demo runtime surface contract suite: runtime package build failed" >&2
  echo "cjgui stage585 form commit demo runtime surface contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage585_form_commit_demo_runtime_surface_contract_suite_version=1"
  echo "stage584_form_commit_cycle_executor_suite_packet=$STAGE584_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage585_form_commit_demo_runtime_surface_contract_owner_passed=true"
  echo "stage584_form_commit_cycle_executor_consumed=true"
  echo "stage583_form_input_event_commit_preview_consumed_transitively=true"
  echo "stage582_form_demo_runtime_surface_contract_consumed_transitively=true"
  echo "shared_form_commit_demo_runtime_surface_contract_materialized=true"
  echo "shared_form_commit_demo_runtime_surface_helper_materialized=true"
  echo "shared_form_commit_execution_receipt_contract_materialized=true"
  echo "todo_checkable_form_commit_runtime_surface_materialized=true"
  echo "settings_checkable_form_commit_runtime_surface_materialized=true"
  echo "ai_generated_settings_checkable_form_commit_runtime_surface_materialized=true"
  echo "chat_composer_checkable_form_commit_runtime_surface_materialized=true"
  echo "form_commit_demo_runtime_surface_bound_to_stage584_cycle_receipts=true"
  echo "form_commit_demo_runtime_surface_bound_to_stage583_commit_preview=true"
  echo "form_commit_demo_runtime_surface_bound_to_stage582_runtime_surfaces=true"
  echo "per_demo_form_commit_runtime_template_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage585_public_foreign_scan_passed=true"
  echo "stage585_forbidden_native_render_token_scan_passed=true"
  echo "stage585_protected_path_scan_passed=true"
  echo "stage586_component_runtime_form_commit_result_surface_refresh_prepared=true"
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
  echo "next_route=stage586_component_runtime_form_commit_result_surface_refresh_after_stage585"
  echo "stage585_form_commit_demo_runtime_surface_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage585 form commit demo runtime surface contract suite: route_classification=form_commit_demo_runtime_surface_contract_ready"
echo "cjgui stage585 form commit demo runtime surface contract suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage585 form commit demo runtime surface contract suite: consumed_stage584=true"
echo "cjgui stage585 form commit demo runtime surface contract suite: visibility_published=false"
