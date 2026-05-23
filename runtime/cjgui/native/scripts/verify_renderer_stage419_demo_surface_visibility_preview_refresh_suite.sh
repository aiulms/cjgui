#!/usr/bin/env zsh
#
# 维护注释：stage419 focused suite 消费 stage418 visibility command plan packet，
# 验证 command plan 能回灌到 Todo/settings/AI-generated settings owner-local visible surface preview refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE419_TMPDIR:-/tmp/cjgui-stage419-demo-surface-visibility-preview-refresh-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage419-demo-surface-visibility-preview-refresh-suite.packet"
STAGE418_SUITE_PACKET="${CJGUI_STAGE419_INPUT_PACKET:-${CJGUI_STAGE418_VISIBILITY_COMMAND_PLAN_DRY_RUN_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage419_demo_surface_visibility_preview_refresh_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage419_demo_surface_visibility_preview_refresh.cj"
OWNER_LOG="$TMP_DIR/stage419-demo-surface-visibility-preview-refresh-owner.log"

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
    echo "cjgui stage419 demo surface visibility preview refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage419 demo surface visibility preview refresh suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage418_visibility_command_plan_dry_run_consumed=true" \
  "visibility_command_plan_dry_run_consumed=true" \
  "accepted_gate_to_preview_visibility_command_consumed=true" \
  "blocked_gate_to_rollback_visibility_command_consumed=true" \
  "demo_surface_visibility_preview_refresh_materialized=true" \
  "todo_visible_surface_preview_refreshed=true" \
  "settings_visible_surface_preview_refreshed=true" \
  "ai_generated_settings_visible_surface_preview_refreshed=true" \
  "accepted_visibility_command_to_visible_surface_preview_mapped=true" \
  "blocked_visibility_command_to_rollback_surface_preview_mapped=true" \
  "demo_surface_visibility_refresh_owner_local=true" \
  "demo_surface_visibility_refresh_preview_only=true" \
  "stage420_visibility_preview_diff_render_command_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE418_SUITE_PACKET" || ! -f "$STAGE418_SUITE_PACKET" ]]; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: missing stage418 packet; set CJGUI_STAGE419_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage418_visibility_command_plan_dry_run_suite_version=1" \
  "stage417_owner_acceptance_visibility_gate_consumed=true" \
  "stage416_commit_result_state_render_reconciliation_consumed_transitively=true" \
  "stage415_commit_result_surface_refresh_consumed_transitively=true" \
  "stage414_gated_replay_commit_executor_dry_run_consumed_transitively=true" \
  "stage413_gated_replay_commit_intent_consumed_transitively=true" \
  "stage412_gated_replay_state_render_refresh_consumed_transitively=true" \
  "stage411_replay_acceptance_gate_consumed_transitively=true" \
  "stage410_replay_result_reconciliation_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "owner_acceptance_visibility_gate_consumed=true" \
  "todo_owner_acceptance_visibility_gate_consumed=true" \
  "settings_owner_acceptance_visibility_gate_consumed=true" \
  "ai_generated_settings_owner_acceptance_visibility_gate_consumed=true" \
  "accepted_reconciliation_gate_candidate_consumed=true" \
  "blocked_reconciliation_visibility_denial_candidate_consumed=true" \
  "visibility_command_plan_dry_run_materialized=true" \
  "todo_visibility_command_plan_dry_run_materialized=true" \
  "settings_visibility_command_plan_dry_run_materialized=true" \
  "ai_generated_settings_visibility_command_plan_dry_run_materialized=true" \
  "accepted_gate_to_preview_visibility_command_mapped=true" \
  "blocked_gate_to_rollback_visibility_command_mapped=true" \
  "visibility_command_plan_bound_to_stage417_gate=true" \
  "visibility_command_plan_bound_to_stage416_reconciliation=true" \
  "visibility_command_plan_owner_local=true" \
  "visibility_command_plan_preview_only=true" \
  "stage419_demo_surface_visibility_preview_refresh_prepared=true" \
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
  require_file_fact "$STAGE418_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage419 demo surface visibility preview refresh suite: runtime package build failed" >&2
  echo "cjgui stage419 demo surface visibility preview refresh suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage418_next_route="$(fact_value "$STAGE418_SUITE_PACKET" "next_route")"

{
  echo "stage419_demo_surface_visibility_preview_refresh_suite_version=1"
  echo "stage418_visibility_command_plan_dry_run_suite_packet=$STAGE418_SUITE_PACKET"
  echo "stage418_next_route=$stage418_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage419_demo_surface_visibility_preview_refresh_owner_passed=true"
  echo "stage418_visibility_command_plan_dry_run_consumed=true"
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
  echo "visibility_command_plan_dry_run_consumed=true"
  echo "todo_visibility_command_plan_dry_run_consumed=true"
  echo "settings_visibility_command_plan_dry_run_consumed=true"
  echo "ai_generated_settings_visibility_command_plan_dry_run_consumed=true"
  echo "accepted_gate_to_preview_visibility_command_consumed=true"
  echo "blocked_gate_to_rollback_visibility_command_consumed=true"
  echo "demo_surface_visibility_preview_refresh_materialized=true"
  echo "todo_visible_surface_preview_refreshed=true"
  echo "settings_visible_surface_preview_refreshed=true"
  echo "ai_generated_settings_visible_surface_preview_refreshed=true"
  echo "accepted_visibility_command_to_visible_surface_preview_mapped=true"
  echo "blocked_visibility_command_to_rollback_surface_preview_mapped=true"
  echo "demo_surface_visibility_refresh_bound_to_stage418_command_plan=true"
  echo "demo_surface_visibility_refresh_bound_to_stage417_gate=true"
  echo "demo_surface_visibility_refresh_owner_local=true"
  echo "demo_surface_visibility_refresh_preview_only=true"
  echo "stage420_visibility_preview_diff_render_command_refresh_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage419_public_foreign_scan_passed=true"
  echo "stage419_forbidden_native_render_token_scan_passed=true"
  echo "stage419_protected_path_scan_passed=true"
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
  echo "next_route=stage420_visibility_preview_diff_render_command_refresh_after_stage419"
  echo "stage419_demo_surface_visibility_preview_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage419 demo surface visibility preview refresh suite: route_classification=demo_surface_visibility_preview_refresh_ready"
echo "cjgui stage419 demo surface visibility preview refresh suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage419 demo surface visibility preview refresh suite: consumed_stage418=true"
echo "cjgui stage419 demo surface visibility preview refresh suite: visibility_published=false"
