#!/usr/bin/env zsh
#
# 维护注释：stage445 focused suite 消费 stage444 recovery RenderCommand refresh packet，
# 验证 refreshed command 能进入 Todo/settings/AI-generated settings recovery demo surface dry-run batch。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE445_TMPDIR:-/tmp/cjgui-stage445-transaction-visibility-recovery-render-command-refresh-demo-surface-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage445-transaction-visibility-recovery-render-command-refresh-demo-surface-dry-run-suite.packet"
STAGE444_SUITE_PACKET="${CJGUI_STAGE445_INPUT_PACKET:-${CJGUI_STAGE444_TRANSACTION_VISIBILITY_RECOVERY_STATE_UPDATE_RENDER_COMMAND_REFRESH_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage445-transaction-visibility-recovery-render-command-refresh-demo-surface-dry-run-owner.log"

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
    echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true" \
  "transaction_visibility_recovery_state_update_render_command_refresh_consumed=true" \
  "todo_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true" \
  "settings_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true" \
  "ai_generated_settings_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true" \
  "transaction_visibility_recovery_demo_surface_render_command_refresh_dry_run_materialized=true" \
  "todo_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true" \
  "settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true" \
  "ai_generated_settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true" \
  "transaction_visibility_recovery_demo_surface_semantic_component_projection_materialized=true" \
  "todo_transaction_visibility_recovery_demo_surface_semantic_node_projected=true" \
  "settings_transaction_visibility_recovery_demo_surface_semantic_node_projected=true" \
  "ai_generated_settings_transaction_visibility_recovery_demo_surface_semantic_node_projected=true" \
  "transaction_visibility_recovery_render_command_refresh_to_demo_surface_dry_run_bound=true" \
  "recovery_demo_surface_dry_run_to_stage443_recovery_state_update_candidate_bound=true" \
  "transaction_visibility_recovery_demo_surface_dry_run_preview_only=true" \
  "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE444_SUITE_PACKET" || ! -f "$STAGE444_SUITE_PACKET" ]]; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: missing stage444 packet; set CJGUI_STAGE445_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage444_transaction_visibility_recovery_state_update_render_command_refresh_suite_version=1" \
  "stage443_transaction_visibility_recovery_action_state_update_dry_run_consumed=true" \
  "stage442_transaction_visibility_result_recovery_action_adapter_consumed_transitively=true" \
  "stage441_transaction_visibility_result_demo_surface_refresh_consumed_transitively=true" \
  "stage440_transaction_visibility_not_published_result_boundary_consumed_transitively=true" \
  "stage439_transaction_visibility_publication_preflight_consumed_transitively=true" \
  "stage438_transaction_visibility_command_plan_consumed_transitively=true" \
  "stage437_transaction_visibility_render_command_transaction_admission_consumed_transitively=true" \
  "stage436_transaction_visibility_render_command_gate_transaction_dry_run_consumed_transitively=true" \
  "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_consumed_transitively=true" \
  "stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run_consumed_transitively=true" \
  "stage433_transaction_visibility_state_update_render_command_refresh_consumed_transitively=true" \
  "stage432_transaction_visibility_action_intent_state_update_dry_run_consumed_transitively=true" \
  "stage431_transaction_visibility_preview_input_event_action_adapter_consumed_transitively=true" \
  "stage430_transaction_visibility_preview_diff_render_command_refresh_consumed_transitively=true" \
  "stage429_demo_surface_transaction_visibility_preview_refresh_consumed_transitively=true" \
  "stage428_render_command_transaction_visibility_command_plan_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "transaction_visibility_recovery_state_update_render_command_refresh_materialized=true" \
  "todo_transaction_visibility_recovery_state_update_render_command_refreshed=true" \
  "settings_transaction_visibility_recovery_state_update_render_command_refreshed=true" \
  "ai_generated_settings_transaction_visibility_recovery_state_update_render_command_refreshed=true" \
  "transaction_visibility_recovery_state_update_candidate_to_render_command_refresh_bound=true" \
  "transaction_visibility_recovery_rollback_preview_to_render_command_refresh_bound=true" \
  "transaction_visibility_recovery_render_command_refresh_preview_only=true" \
  "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_prepared=true" \
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
  require_file_fact "$STAGE444_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: runtime package build failed" >&2
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage444_next_route="$(fact_value "$STAGE444_SUITE_PACKET" "next_route")"

{
  echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_suite_version=1"
  echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_suite_packet=$STAGE444_SUITE_PACKET"
  echo "stage444_next_route=$stage444_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_owner_passed=true"
  echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
  echo "stage443_transaction_visibility_recovery_action_state_update_dry_run_consumed_transitively=true"
  echo "stage442_transaction_visibility_result_recovery_action_adapter_consumed_transitively=true"
  echo "stage441_transaction_visibility_result_demo_surface_refresh_consumed_transitively=true"
  echo "stage440_transaction_visibility_not_published_result_boundary_consumed_transitively=true"
  echo "stage439_transaction_visibility_publication_preflight_consumed_transitively=true"
  echo "stage438_transaction_visibility_command_plan_consumed_transitively=true"
  echo "stage437_transaction_visibility_render_command_transaction_admission_consumed_transitively=true"
  echo "stage436_transaction_visibility_render_command_gate_transaction_dry_run_consumed_transitively=true"
  echo "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_consumed_transitively=true"
  echo "stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run_consumed_transitively=true"
  echo "stage433_transaction_visibility_state_update_render_command_refresh_consumed_transitively=true"
  echo "stage432_transaction_visibility_action_intent_state_update_dry_run_consumed_transitively=true"
  echo "stage431_transaction_visibility_preview_input_event_action_adapter_consumed_transitively=true"
  echo "stage430_transaction_visibility_preview_diff_render_command_refresh_consumed_transitively=true"
  echo "stage429_demo_surface_transaction_visibility_preview_refresh_consumed_transitively=true"
  echo "stage428_render_command_transaction_visibility_command_plan_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
  echo "todo_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
  echo "settings_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
  echo "ai_generated_settings_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
  echo "transaction_visibility_recovery_demo_surface_render_command_refresh_dry_run_materialized=true"
  echo "todo_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true"
  echo "settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true"
  echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true"
  echo "transaction_visibility_recovery_demo_surface_semantic_component_projection_materialized=true"
  echo "todo_transaction_visibility_recovery_demo_surface_semantic_node_projected=true"
  echo "settings_transaction_visibility_recovery_demo_surface_semantic_node_projected=true"
  echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_semantic_node_projected=true"
  echo "transaction_visibility_recovery_render_command_refresh_to_demo_surface_dry_run_bound=true"
  echo "recovery_demo_surface_dry_run_to_stage443_recovery_state_update_candidate_bound=true"
  echo "transaction_visibility_recovery_render_command_refresh_batch_owner_local=true"
  echo "transaction_visibility_recovery_demo_surface_dry_run_preview_only=true"
  echo "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage445_public_foreign_scan_passed=true"
  echo "stage445_forbidden_native_render_token_scan_passed=true"
  echo "stage445_protected_path_scan_passed=true"
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
  echo "next_route=stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_after_stage445"
  echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: route_classification=transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_ready"
echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: consumed_stage444=true"
echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run suite: renderer_state_write=false"
