#!/usr/bin/env zsh
#
# 维护注释：stage456 focused suite 消费 stage455 execution receipt packet，
# 验证 receipt 可映射为 owner-local focus/input action intent adapter。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE456_TMPDIR:-/tmp/cjgui-stage456-recovery-demo-surface-focus-input-action-intent-adapter-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage456-recovery-demo-surface-focus-input-action-intent-adapter-suite.packet"
STAGE455_SUITE_PACKET="${CJGUI_STAGE456_INPUT_PACKET:-${CJGUI_STAGE455_RECOVERY_DEMO_SURFACE_LAYOUT_STYLE_EXECUTION_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage456_recovery_demo_surface_focus_input_action_intent_adapter_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage456_recovery_demo_surface_focus_input_action_intent_adapter.cj"
OWNER_LOG="$TMP_DIR/stage456-recovery-demo-surface-focus-input-action-intent-adapter-owner.log"

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
    echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage455_recovery_demo_surface_layout_style_execution_dry_run_consumed=true" \
  "shared_recovery_demo_surface_layout_style_execution_receipt_consumed=true" \
  "recovery_demo_surface_text_focus_execution_affordance_consumed=true" \
  "todo_recovery_demo_surface_focus_activation_action_intent_materialized=true" \
  "settings_recovery_demo_surface_toggle_focus_action_intent_materialized=true" \
  "ai_generated_settings_recovery_demo_surface_submit_focus_action_intent_materialized=true" \
  "shared_recovery_demo_surface_focus_input_action_intent_adapter_materialized=true" \
  "execution_receipt_to_focus_input_action_intent_adapter_bound=true" \
  "layout_style_preview_to_focus_input_action_intent_adapter_bound=true" \
  "recovery_demo_surface_focus_input_action_intent_owner_local=true" \
  "recovery_demo_surface_focus_input_action_intent_non_dispatching=true" \
  "stage457_recovery_demo_surface_focus_input_action_state_update_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE455_SUITE_PACKET" || ! -f "$STAGE455_SUITE_PACKET" ]]; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: missing stage455 packet; set CJGUI_STAGE456_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage455_recovery_demo_surface_layout_style_execution_dry_run_suite_version=1" \
  "stage454_recovery_demo_surface_render_command_layout_style_preview_consumed=true" \
  "stage453_recovery_demo_surface_state_update_render_command_refresh_consumed_transitively=true" \
  "stage452_recovery_demo_surface_action_executor_state_update_dry_run_consumed_transitively=true" \
  "stage451_recovery_demo_surface_execution_action_executor_preview_consumed_transitively=true" \
  "stage450_recovery_demo_surface_execution_dry_run_consumed_transitively=true" \
  "stage449_recovery_demo_surface_render_command_refresh_dry_run_consumed_transitively=true" \
  "stage448_recovery_demo_surface_state_update_render_command_refresh_consumed_transitively=true" \
  "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_consumed_transitively=true" \
  "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_consumed_transitively=true" \
  "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_consumed_transitively=true" \
  "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed_transitively=true" \
  "stage443_transaction_visibility_recovery_action_state_update_dry_run_consumed_transitively=true" \
  "stage442_transaction_visibility_result_recovery_action_adapter_consumed_transitively=true" \
  "stage441_transaction_visibility_result_demo_surface_refresh_consumed_transitively=true" \
  "stage440_transaction_visibility_not_published_result_boundary_consumed_transitively=true" \
  "shared_recovery_demo_surface_layout_style_execution_receipt_materialized=true" \
  "todo_recovery_demo_surface_layout_style_execution_dry_run_materialized=true" \
  "settings_recovery_demo_surface_layout_style_execution_dry_run_materialized=true" \
  "ai_generated_settings_recovery_demo_surface_layout_style_execution_dry_run_materialized=true" \
  "recovery_demo_surface_text_focus_execution_affordance_materialized=true" \
  "layout_style_preview_to_execution_dry_run_bound=true" \
  "render_command_refresh_to_execution_receipt_bound=true" \
  "recovery_demo_surface_layout_style_execution_owner_local=true" \
  "recovery_demo_surface_layout_style_execution_dry_run_only=true" \
  "stage456_recovery_demo_surface_focus_input_action_intent_adapter_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "layout_engine_enabled=false" \
  "style_resolver_enabled=false" \
  "text_shaping_enabled=false" \
  "focus_manager_enabled=false" \
  "backend_implementation=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE455_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: runtime package build failed" >&2
  echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage455_next_route="$(fact_value "$STAGE455_SUITE_PACKET" "next_route")"

{
  echo "stage456_recovery_demo_surface_focus_input_action_intent_adapter_suite_version=1"
  echo "stage455_recovery_demo_surface_layout_style_execution_suite_packet=$STAGE455_SUITE_PACKET"
  echo "stage455_next_route=$stage455_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage456_recovery_demo_surface_focus_input_action_intent_adapter_owner_passed=true"
  echo "stage455_recovery_demo_surface_layout_style_execution_dry_run_consumed=true"
  echo "stage454_recovery_demo_surface_render_command_layout_style_preview_consumed_transitively=true"
  echo "stage453_recovery_demo_surface_state_update_render_command_refresh_consumed_transitively=true"
  echo "stage452_recovery_demo_surface_action_executor_state_update_dry_run_consumed_transitively=true"
  echo "stage451_recovery_demo_surface_execution_action_executor_preview_consumed_transitively=true"
  echo "stage450_recovery_demo_surface_execution_dry_run_consumed_transitively=true"
  echo "stage449_recovery_demo_surface_render_command_refresh_dry_run_consumed_transitively=true"
  echo "stage448_recovery_demo_surface_state_update_render_command_refresh_consumed_transitively=true"
  echo "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_consumed_transitively=true"
  echo "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_consumed_transitively=true"
  echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_consumed_transitively=true"
  echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed_transitively=true"
  echo "stage443_transaction_visibility_recovery_action_state_update_dry_run_consumed_transitively=true"
  echo "stage442_transaction_visibility_result_recovery_action_adapter_consumed_transitively=true"
  echo "stage441_transaction_visibility_result_demo_surface_refresh_consumed_transitively=true"
  echo "stage440_transaction_visibility_not_published_result_boundary_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_recovery_demo_surface_layout_style_execution_receipt_consumed=true"
  echo "recovery_demo_surface_text_focus_execution_affordance_consumed=true"
  echo "todo_recovery_demo_surface_focus_activation_action_intent_materialized=true"
  echo "settings_recovery_demo_surface_toggle_focus_action_intent_materialized=true"
  echo "ai_generated_settings_recovery_demo_surface_submit_focus_action_intent_materialized=true"
  echo "shared_recovery_demo_surface_focus_input_action_intent_adapter_materialized=true"
  echo "execution_receipt_to_focus_input_action_intent_adapter_bound=true"
  echo "layout_style_preview_to_focus_input_action_intent_adapter_bound=true"
  echo "recovery_demo_surface_focus_input_action_intent_owner_local=true"
  echo "recovery_demo_surface_focus_input_action_intent_non_dispatching=true"
  echo "runtime_package_build_passed=true"
  echo "stage456_public_foreign_scan_passed=true"
  echo "stage456_forbidden_native_render_token_scan_passed=true"
  echo "stage456_protected_path_scan_passed=true"
  echo "stage457_recovery_demo_surface_focus_input_action_state_update_dry_run_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "text_shaping_enabled=false"
  echo "focus_manager_enabled=false"
  echo "backend_implementation=false"
  echo "concrete_platform_capability_promise=false"
  echo "platform_command_buffer=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage457_recovery_demo_surface_focus_input_action_state_update_dry_run_after_stage456"
  echo "stage456_recovery_demo_surface_focus_input_action_intent_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: route_classification=recovery_demo_surface_focus_input_action_intent_adapter_ready"
echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: consumed_stage455=true"
echo "cjgui stage456 recovery demo surface focus input action intent adapter suite: action_dispatch=false"
