#!/usr/bin/env zsh
#
# 维护注释：stage454 focused suite 消费 stage453 RenderCommand refresh packet，
# 验证 refreshed commands 可投影为共享 layout/style/text/focus preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE454_TMPDIR:-/tmp/cjgui-stage454-recovery-demo-surface-render-command-layout-style-preview-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage454-recovery-demo-surface-render-command-layout-style-preview-suite.packet"
STAGE453_SUITE_PACKET="${CJGUI_STAGE454_INPUT_PACKET:-${CJGUI_STAGE453_RECOVERY_DEMO_SURFACE_STATE_UPDATE_RENDER_COMMAND_REFRESH_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage454_recovery_demo_surface_render_command_layout_style_preview_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage454_recovery_demo_surface_render_command_layout_style_preview.cj"
OWNER_LOG="$TMP_DIR/stage454-recovery-demo-surface-render-command-layout-style-preview-owner.log"

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
    echo "cjgui stage454 recovery demo surface render command layout style preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage453_recovery_demo_surface_state_update_render_command_refresh_consumed=true" \
  "recovery_demo_surface_render_command_refresh_preview_consumed=true" \
  "todo_recovery_demo_surface_state_update_render_command_consumed=true" \
  "settings_recovery_demo_surface_state_update_render_command_consumed=true" \
  "ai_generated_settings_recovery_demo_surface_state_update_render_command_consumed=true" \
  "shared_recovery_demo_surface_layout_style_text_focus_preview_materialized=true" \
  "todo_recovery_demo_surface_layout_style_text_focus_node_materialized=true" \
  "settings_recovery_demo_surface_layout_style_text_focus_node_materialized=true" \
  "ai_generated_settings_recovery_demo_surface_layout_style_text_focus_node_materialized=true" \
  "render_command_refresh_to_layout_style_preview_bound=true" \
  "stage452_state_update_to_layout_style_preview_bound=true" \
  "recovery_demo_surface_layout_style_preview_owner_local=true" \
  "recovery_demo_surface_layout_style_preview_dry_run_only=true" \
  "stage455_recovery_demo_surface_layout_style_execution_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE453_SUITE_PACKET" || ! -f "$STAGE453_SUITE_PACKET" ]]; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: missing stage453 packet; set CJGUI_STAGE454_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage453_recovery_demo_surface_state_update_render_command_refresh_suite_version=1" \
  "stage452_recovery_demo_surface_action_executor_state_update_dry_run_consumed=true" \
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
  "recovery_demo_surface_action_executor_state_update_dry_run_consumed=true" \
  "recovery_demo_surface_state_update_render_command_refresh_materialized=true" \
  "todo_recovery_demo_surface_state_update_render_command_refreshed=true" \
  "settings_recovery_demo_surface_state_update_render_command_refreshed=true" \
  "ai_generated_settings_recovery_demo_surface_state_update_render_command_refreshed=true" \
  "action_executor_state_update_candidate_to_render_command_refresh_bound=true" \
  "stage451_action_executor_preview_to_render_command_refresh_bound=true" \
  "stage450_execution_receipt_to_render_command_refresh_bound=true" \
  "recovery_demo_surface_render_command_refresh_owner_local=true" \
  "recovery_demo_surface_render_command_refresh_preview_only=true" \
  "stage454_recovery_demo_surface_render_command_layout_style_preview_prepared=true" \
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
  "backend_implementation=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE453_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: runtime package build failed" >&2
  echo "cjgui stage454 recovery demo surface render command layout style preview suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage453_next_route="$(fact_value "$STAGE453_SUITE_PACKET" "next_route")"

{
  echo "stage454_recovery_demo_surface_render_command_layout_style_preview_suite_version=1"
  echo "stage453_recovery_demo_surface_state_update_render_command_refresh_suite_packet=$STAGE453_SUITE_PACKET"
  echo "stage453_next_route=$stage453_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage454_recovery_demo_surface_render_command_layout_style_preview_owner_passed=true"
  echo "stage453_recovery_demo_surface_state_update_render_command_refresh_consumed=true"
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
  echo "recovery_demo_surface_render_command_refresh_preview_consumed=true"
  echo "todo_recovery_demo_surface_state_update_render_command_consumed=true"
  echo "settings_recovery_demo_surface_state_update_render_command_consumed=true"
  echo "ai_generated_settings_recovery_demo_surface_state_update_render_command_consumed=true"
  echo "shared_recovery_demo_surface_layout_style_text_focus_preview_materialized=true"
  echo "todo_recovery_demo_surface_layout_style_text_focus_node_materialized=true"
  echo "settings_recovery_demo_surface_layout_style_text_focus_node_materialized=true"
  echo "ai_generated_settings_recovery_demo_surface_layout_style_text_focus_node_materialized=true"
  echo "render_command_refresh_to_layout_style_preview_bound=true"
  echo "stage452_state_update_to_layout_style_preview_bound=true"
  echo "recovery_demo_surface_layout_style_preview_owner_local=true"
  echo "recovery_demo_surface_layout_style_preview_dry_run_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage454_public_foreign_scan_passed=true"
  echo "stage454_forbidden_native_render_token_scan_passed=true"
  echo "stage454_protected_path_scan_passed=true"
  echo "stage455_recovery_demo_surface_layout_style_execution_dry_run_prepared=true"
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
  echo "next_route=stage455_recovery_demo_surface_layout_style_execution_dry_run_after_stage454"
  echo "stage454_recovery_demo_surface_render_command_layout_style_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage454 recovery demo surface render command layout style preview suite: route_classification=recovery_demo_surface_render_command_layout_style_preview_ready"
echo "cjgui stage454 recovery demo surface render command layout style preview suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage454 recovery demo surface render command layout style preview suite: consumed_stage453=true"
echo "cjgui stage454 recovery demo surface render command layout style preview suite: layout_engine_enabled=false"
