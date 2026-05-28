#!/usr/bin/env zsh
#
# 维护注释：stage425 focused suite 消费 stage424 demo surface batch packet，
# 验证 refreshed RenderCommand batch 能进入 owner-local accept/reject gate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE425_TMPDIR:-/tmp/cjgui-stage425-render-command-refresh-owner-acceptance-gate-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage425-render-command-refresh-owner-acceptance-gate-suite.packet"
STAGE424_SUITE_PACKET="${CJGUI_STAGE425_INPUT_PACKET:-${CJGUI_STAGE424_RENDER_COMMAND_REFRESH_DEMO_SURFACE_DRY_RUN_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage425_render_command_refresh_owner_acceptance_gate_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage425_render_command_refresh_owner_acceptance_gate.cj"
OWNER_LOG="$TMP_DIR/stage425-render-command-refresh-owner-acceptance-gate-owner.log"

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
    echo "cjgui stage425 render command refresh owner acceptance gate suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage425 render command refresh owner acceptance gate suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage424_render_command_refresh_demo_surface_dry_run_consumed=true" \
  "demo_surface_render_command_refresh_dry_run_consumed=true" \
  "todo_demo_surface_render_command_refresh_batch_consumed=true" \
  "settings_demo_surface_render_command_refresh_batch_consumed=true" \
  "ai_generated_settings_demo_surface_render_command_refresh_batch_consumed=true" \
  "render_command_refresh_owner_acceptance_gate_materialized=true" \
  "todo_render_command_refresh_owner_acceptance_gate_materialized=true" \
  "settings_render_command_refresh_owner_acceptance_gate_materialized=true" \
  "ai_generated_settings_render_command_refresh_owner_acceptance_gate_materialized=true" \
  "owner_acceptance_token_for_render_command_refresh_required=true" \
  "owner_reject_reason_for_render_command_refresh_required=true" \
  "accepted_render_command_gate_candidate_prepared=true" \
  "blocked_render_command_rollback_candidate_prepared=true" \
  "gate_bound_to_stage424_demo_surface_batch=true" \
  "gate_bound_to_stage423_render_command_refresh=true" \
  "owner_acceptance_gate_owner_local=true" \
  "owner_acceptance_gate_preview_only=true" \
  "stage426_render_command_gate_transaction_dry_run_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE424_SUITE_PACKET" || ! -f "$STAGE424_SUITE_PACKET" ]]; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: missing stage424 packet; set CJGUI_STAGE425_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage424_render_command_refresh_demo_surface_dry_run_suite_version=1" \
  "stage423_state_update_render_command_refresh_consumed=true" \
  "stage422_action_intent_state_update_dry_run_consumed_transitively=true" \
  "stage421_visibility_preview_input_event_action_adapter_consumed_transitively=true" \
  "stage420_visibility_preview_diff_render_command_refresh_consumed_transitively=true" \
  "stage419_demo_surface_visibility_preview_refresh_consumed_transitively=true" \
  "stage418_visibility_command_plan_dry_run_consumed_transitively=true" \
  "stage417_owner_acceptance_visibility_gate_consumed_transitively=true" \
  "stage416_commit_result_state_render_reconciliation_consumed_transitively=true" \
  "stage415_commit_result_surface_refresh_consumed_transitively=true" \
  "stage414_gated_replay_commit_executor_dry_run_consumed_transitively=true" \
  "stage413_gated_replay_commit_intent_consumed_transitively=true" \
  "stage412_gated_replay_state_render_refresh_consumed_transitively=true" \
  "stage411_replay_acceptance_gate_consumed_transitively=true" \
  "stage410_replay_result_reconciliation_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "state_update_render_command_refresh_consumed=true" \
  "todo_state_update_render_command_refresh_consumed=true" \
  "settings_state_update_render_command_refresh_consumed=true" \
  "ai_generated_settings_state_update_render_command_refresh_consumed=true" \
  "demo_surface_render_command_refresh_dry_run_materialized=true" \
  "todo_demo_surface_render_command_refresh_batch_materialized=true" \
  "settings_demo_surface_render_command_refresh_batch_materialized=true" \
  "ai_generated_settings_demo_surface_render_command_refresh_batch_materialized=true" \
  "render_command_refresh_to_demo_surface_dry_run_bound=true" \
  "demo_surface_dry_run_to_stage422_state_update_candidate_bound=true" \
  "render_command_refresh_batch_owner_local=true" \
  "demo_surface_dry_run_preview_only=true" \
  "stage425_render_command_refresh_owner_acceptance_gate_prepared=true" \
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
  require_file_fact "$STAGE424_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage425 render command refresh owner acceptance gate suite: runtime package build failed" >&2
  echo "cjgui stage425 render command refresh owner acceptance gate suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage424_next_route="$(fact_value "$STAGE424_SUITE_PACKET" "next_route")"

{
  echo "stage425_render_command_refresh_owner_acceptance_gate_suite_version=1"
  echo "stage424_render_command_refresh_demo_surface_dry_run_suite_packet=$STAGE424_SUITE_PACKET"
  echo "stage424_next_route=$stage424_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage425_render_command_refresh_owner_acceptance_gate_owner_passed=true"
  echo "stage424_render_command_refresh_demo_surface_dry_run_consumed=true"
  echo "stage423_state_update_render_command_refresh_consumed_transitively=true"
  echo "stage422_action_intent_state_update_dry_run_consumed_transitively=true"
  echo "stage421_visibility_preview_input_event_action_adapter_consumed_transitively=true"
  echo "stage420_visibility_preview_diff_render_command_refresh_consumed_transitively=true"
  echo "stage419_demo_surface_visibility_preview_refresh_consumed_transitively=true"
  echo "stage418_visibility_command_plan_dry_run_consumed_transitively=true"
  echo "stage417_owner_acceptance_visibility_gate_consumed_transitively=true"
  echo "stage416_commit_result_state_render_reconciliation_consumed_transitively=true"
  echo "stage415_commit_result_surface_refresh_consumed_transitively=true"
  echo "stage414_gated_replay_commit_executor_dry_run_consumed_transitively=true"
  echo "stage413_gated_replay_commit_intent_consumed_transitively=true"
  echo "stage412_gated_replay_state_render_refresh_consumed_transitively=true"
  echo "stage411_replay_acceptance_gate_consumed_transitively=true"
  echo "stage410_replay_result_reconciliation_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "demo_surface_render_command_refresh_dry_run_consumed=true"
  echo "todo_demo_surface_render_command_refresh_batch_consumed=true"
  echo "settings_demo_surface_render_command_refresh_batch_consumed=true"
  echo "ai_generated_settings_demo_surface_render_command_refresh_batch_consumed=true"
  echo "render_command_refresh_owner_acceptance_gate_materialized=true"
  echo "todo_render_command_refresh_owner_acceptance_gate_materialized=true"
  echo "settings_render_command_refresh_owner_acceptance_gate_materialized=true"
  echo "ai_generated_settings_render_command_refresh_owner_acceptance_gate_materialized=true"
  echo "owner_acceptance_token_for_render_command_refresh_required=true"
  echo "owner_reject_reason_for_render_command_refresh_required=true"
  echo "accepted_render_command_gate_candidate_prepared=true"
  echo "blocked_render_command_rollback_candidate_prepared=true"
  echo "gate_bound_to_stage424_demo_surface_batch=true"
  echo "gate_bound_to_stage423_render_command_refresh=true"
  echo "owner_acceptance_gate_owner_local=true"
  echo "owner_acceptance_gate_preview_only=true"
  echo "stage426_render_command_gate_transaction_dry_run_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage425_public_foreign_scan_passed=true"
  echo "stage425_forbidden_native_render_token_scan_passed=true"
  echo "stage425_protected_path_scan_passed=true"
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
  echo "next_route=stage426_render_command_gate_transaction_dry_run_after_stage425"
  echo "stage425_render_command_refresh_owner_acceptance_gate_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage425 render command refresh owner acceptance gate suite: route_classification=render_command_refresh_owner_acceptance_gate_ready"
echo "cjgui stage425 render command refresh owner acceptance gate suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage425 render command refresh owner acceptance gate suite: consumed_stage424=true"
echo "cjgui stage425 render command refresh owner acceptance gate suite: owner_acceptance_granted=false"
