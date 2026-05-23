#!/usr/bin/env zsh
#
# 维护注释：stage414 focused suite 消费 stage413 commit intent packet，
# 验证 commit intent 能推进到 guarded executor dry-run 与 rollback / visibility denial boundary。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE414_TMPDIR:-/tmp/cjgui-stage414-gated-replay-commit-executor-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage414-gated-replay-commit-executor-dry-run-suite.packet"
STAGE413_SUITE_PACKET="${CJGUI_STAGE414_INPUT_PACKET:-${CJGUI_STAGE413_GATED_REPLAY_COMMIT_INTENT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage414_gated_replay_commit_executor_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage414_gated_replay_commit_executor_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage414-gated-replay-commit-executor-dry-run-owner.log"

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
    echo "cjgui stage414 gated replay commit executor dry run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage414 gated replay commit executor dry run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage414 gated replay commit executor dry run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage414 gated replay commit executor dry run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage414 gated replay commit executor dry run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage413_gated_replay_commit_intent_consumed=true" \
  "demo_surface_gated_replay_commit_intent_consumed=true" \
  "guarded_commit_executor_input_consumed=true" \
  "guarded_replay_commit_executor_dry_run_materialized=true" \
  "guarded_replay_commit_executor_result_preview_materialized=true" \
  "accepted_commit_intent_pending_owner_acceptance_classified=true" \
  "blocked_commit_intent_rollback_required_classified=true" \
  "rollback_boundary_preview_materialized=true" \
  "visibility_publication_denial_boundary_materialized=true" \
  "guarded_executor_bound_to_stage413_commit_intent=true" \
  "guarded_executor_bound_to_stage412_refresh=true" \
  "stage415_commit_result_surface_refresh_prepared=true" \
  "gated_replay_commit_executor_owner_local=true" \
  "gated_replay_commit_executor_dry_run_only=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE413_SUITE_PACKET" || ! -f "$STAGE413_SUITE_PACKET" ]]; then
  echo "cjgui stage414 gated replay commit executor dry run suite: missing stage413 packet; set CJGUI_STAGE414_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage413_gated_replay_commit_intent_suite_version=1" \
  "stage412_gated_replay_state_render_refresh_consumed=true" \
  "stage411_replay_acceptance_gate_consumed_transitively=true" \
  "stage410_replay_result_reconciliation_consumed_transitively=true" \
  "stage409_backend_adapter_execution_result_replay_consumed_transitively=true" \
  "stage408_demo_surface_backend_adapter_execution_trace_refresh_consumed_transitively=true" \
  "stage407_demo_surface_backend_adapter_execution_plan_consumed_transitively=true" \
  "stage406_demo_surface_backend_adapter_validation_refresh_consumed_transitively=true" \
  "stage405_demo_surface_backend_adapter_validation_consumed_transitively=true" \
  "stage404_demo_surface_backend_adapter_result_refresh_consumed_transitively=true" \
  "stage403_demo_surface_render_command_backend_adapter_dry_run_consumed_transitively=true" \
  "stage402_demo_surface_render_command_adapter_demo_refresh_consumed_transitively=true" \
  "stage401_demo_surface_execution_result_render_command_adapter_consumed_transitively=true" \
  "stage400_demo_surface_execution_semantic_refresh_consumed_transitively=true" \
  "stage399_demo_surface_event_execution_dry_run_consumed_transitively=true" \
  "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "gated_replay_state_delta_dry_run_consumed=true" \
  "gated_replay_render_command_refresh_consumed=true" \
  "accepted_replay_state_delta_candidate_consumed=true" \
  "blocked_replay_rollback_candidate_consumed=true" \
  "demo_surface_gated_replay_commit_intent_materialized=true" \
  "todo_gated_replay_commit_intent_materialized=true" \
  "settings_gated_replay_commit_intent_materialized=true" \
  "ai_generated_settings_gated_replay_commit_intent_materialized=true" \
  "commit_intent_bound_to_owner_acceptance_requirement=true" \
  "commit_intent_bound_to_stage412_refresh=true" \
  "commit_intent_bound_to_stage411_gate=true" \
  "guarded_commit_executor_input_prepared=true" \
  "gated_replay_commit_intent_owner_local=true" \
  "gated_replay_commit_intent_dry_run_only=true" \
  "stage414_gated_replay_commit_executor_dry_run_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "layout_engine_enabled=false" \
  "input_event_pipeline_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "backend_implementation=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE413_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage414 gated replay commit executor dry run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage414 gated replay commit executor dry run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage414 gated replay commit executor dry run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage414 gated replay commit executor dry run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage414 gated replay commit executor dry run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage414 gated replay commit executor dry run suite: runtime package build failed" >&2
  echo "cjgui stage414 gated replay commit executor dry run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage413_next_route="$(fact_value "$STAGE413_SUITE_PACKET" "next_route")"

{
  echo "stage414_gated_replay_commit_executor_dry_run_suite_version=1"
  echo "stage413_gated_replay_commit_intent_suite_packet=$STAGE413_SUITE_PACKET"
  echo "stage413_next_route=$stage413_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage414_gated_replay_commit_executor_dry_run_owner_passed=true"
  echo "stage413_gated_replay_commit_intent_consumed=true"
  echo "stage412_gated_replay_state_render_refresh_consumed_transitively=true"
  echo "stage411_replay_acceptance_gate_consumed_transitively=true"
  echo "stage410_replay_result_reconciliation_consumed_transitively=true"
  echo "stage409_backend_adapter_execution_result_replay_consumed_transitively=true"
  echo "stage408_demo_surface_backend_adapter_execution_trace_refresh_consumed_transitively=true"
  echo "stage407_demo_surface_backend_adapter_execution_plan_consumed_transitively=true"
  echo "stage406_demo_surface_backend_adapter_validation_refresh_consumed_transitively=true"
  echo "stage405_demo_surface_backend_adapter_validation_consumed_transitively=true"
  echo "stage404_demo_surface_backend_adapter_result_refresh_consumed_transitively=true"
  echo "stage403_demo_surface_render_command_backend_adapter_dry_run_consumed_transitively=true"
  echo "stage402_demo_surface_render_command_adapter_demo_refresh_consumed_transitively=true"
  echo "stage401_demo_surface_execution_result_render_command_adapter_consumed_transitively=true"
  echo "stage400_demo_surface_execution_semantic_refresh_consumed_transitively=true"
  echo "stage399_demo_surface_event_execution_dry_run_consumed_transitively=true"
  echo "stage398_component_event_sequence_render_refresh_probe_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "demo_surface_gated_replay_commit_intent_consumed=true"
  echo "guarded_commit_executor_input_consumed=true"
  echo "guarded_replay_commit_executor_dry_run_materialized=true"
  echo "guarded_replay_commit_executor_result_preview_materialized=true"
  echo "accepted_commit_intent_pending_owner_acceptance_classified=true"
  echo "blocked_commit_intent_rollback_required_classified=true"
  echo "rollback_boundary_preview_materialized=true"
  echo "visibility_publication_denial_boundary_materialized=true"
  echo "guarded_executor_bound_to_stage413_commit_intent=true"
  echo "guarded_executor_bound_to_stage412_refresh=true"
  echo "stage415_commit_result_surface_refresh_prepared=true"
  echo "gated_replay_commit_executor_owner_local=true"
  echo "gated_replay_commit_executor_dry_run_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage414_public_foreign_scan_passed=true"
  echo "stage414_forbidden_native_render_token_scan_passed=true"
  echo "stage414_protected_path_scan_passed=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
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
  echo "next_route=stage415_demo_surface_gated_replay_commit_result_refresh_after_stage414"
  echo "stage414_gated_replay_commit_executor_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage414 gated replay commit executor dry run suite: route_classification=gated_replay_commit_executor_dry_run_ready"
echo "cjgui stage414 gated replay commit executor dry run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage414 gated replay commit executor dry run suite: consumed_stage413=true"
echo "cjgui stage414 gated replay commit executor dry run suite: renderer_state_write=false"
