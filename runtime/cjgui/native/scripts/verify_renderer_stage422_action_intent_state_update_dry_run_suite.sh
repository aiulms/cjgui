#!/usr/bin/env zsh
#
# 维护注释：stage422 focused suite 消费 stage421 input event/action intent packet，
# 验证 action intent 能进入 owner-local state update dry-run 和 rollback preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE422_TMPDIR:-/tmp/cjgui-stage422-action-intent-state-update-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage422-action-intent-state-update-dry-run-suite.packet"
STAGE421_SUITE_PACKET="${CJGUI_STAGE422_INPUT_PACKET:-${CJGUI_STAGE421_VISIBILITY_PREVIEW_INPUT_EVENT_ACTION_ADAPTER_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage422_action_intent_state_update_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage422_action_intent_state_update_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage422-action-intent-state-update-dry-run-owner.log"

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
    echo "cjgui stage422 action intent state update dry run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage422 action intent state update dry run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage422 action intent state update dry run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage422 action intent state update dry run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage422 action intent state update dry run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage421_visibility_preview_input_event_action_adapter_consumed=true" \
  "owner_local_action_intent_consumed=true" \
  "action_intent_state_update_dry_run_materialized=true" \
  "todo_action_intent_state_update_candidate_materialized=true" \
  "settings_action_intent_state_update_candidate_materialized=true" \
  "ai_generated_settings_action_intent_state_update_candidate_materialized=true" \
  "action_intent_to_state_update_dry_run_bound=true" \
  "action_intent_rollback_preview_materialized=true" \
  "state_update_dry_run_only=true" \
  "stage423_state_update_render_command_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE421_SUITE_PACKET" || ! -f "$STAGE421_SUITE_PACKET" ]]; then
  echo "cjgui stage422 action intent state update dry run suite: missing stage421 packet; set CJGUI_STAGE422_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage421_visibility_preview_input_event_action_adapter_suite_version=1" \
  "stage420_visibility_preview_diff_render_command_refresh_consumed=true" \
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
  "visibility_preview_diff_consumed=true" \
  "visibility_preview_render_command_refresh_consumed=true" \
  "todo_visibility_preview_diff_consumed=true" \
  "settings_visibility_preview_diff_consumed=true" \
  "ai_generated_settings_visibility_preview_diff_consumed=true" \
  "visibility_preview_input_event_adapter_materialized=true" \
  "todo_visible_preview_input_event_adapter_materialized=true" \
  "settings_visible_preview_input_event_adapter_materialized=true" \
  "ai_generated_settings_visible_preview_input_event_adapter_materialized=true" \
  "todo_visible_preview_input_event_to_action_intent_bound=true" \
  "settings_visible_preview_input_event_to_action_intent_bound=true" \
  "ai_generated_settings_visible_preview_input_event_to_action_intent_bound=true" \
  "owner_local_action_intent_materialized=true" \
  "action_intent_owner_local=true" \
  "action_dispatch=false" \
  "action_intent_non_dispatching=true" \
  "stage422_action_intent_state_update_dry_run_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_enabled=false" \
  "input_event_pipeline_execution=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "state_update_committed=false" \
  "backend_implementation=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE421_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage422 action intent state update dry run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage422 action intent state update dry run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage422 action intent state update dry run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage422 action intent state update dry run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage422 action intent state update dry run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage422 action intent state update dry run suite: runtime package build failed" >&2
  echo "cjgui stage422 action intent state update dry run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage421_next_route="$(fact_value "$STAGE421_SUITE_PACKET" "next_route")"

{
  echo "stage422_action_intent_state_update_dry_run_suite_version=1"
  echo "stage421_visibility_preview_input_event_action_adapter_suite_packet=$STAGE421_SUITE_PACKET"
  echo "stage421_next_route=$stage421_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage422_action_intent_state_update_dry_run_owner_passed=true"
  echo "stage421_visibility_preview_input_event_action_adapter_consumed=true"
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
  echo "owner_local_action_intent_consumed=true"
  echo "todo_visible_preview_input_event_to_action_intent_consumed=true"
  echo "settings_visible_preview_input_event_to_action_intent_consumed=true"
  echo "ai_generated_settings_visible_preview_input_event_to_action_intent_consumed=true"
  echo "action_intent_state_update_dry_run_materialized=true"
  echo "todo_action_intent_state_update_candidate_materialized=true"
  echo "settings_action_intent_state_update_candidate_materialized=true"
  echo "ai_generated_settings_action_intent_state_update_candidate_materialized=true"
  echo "action_intent_to_state_update_dry_run_bound=true"
  echo "action_intent_rollback_preview_materialized=true"
  echo "state_update_dry_run_only=true"
  echo "stage423_state_update_render_command_refresh_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage422_public_foreign_scan_passed=true"
  echo "stage422_forbidden_native_render_token_scan_passed=true"
  echo "stage422_protected_path_scan_passed=true"
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
  echo "next_route=stage423_state_update_render_command_refresh_after_stage422"
  echo "stage422_action_intent_state_update_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage422 action intent state update dry run suite: route_classification=action_intent_state_update_dry_run_ready"
echo "cjgui stage422 action intent state update dry run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage422 action intent state update dry run suite: consumed_stage421=true"
echo "cjgui stage422 action intent state update dry run suite: state_update_committed=false"
