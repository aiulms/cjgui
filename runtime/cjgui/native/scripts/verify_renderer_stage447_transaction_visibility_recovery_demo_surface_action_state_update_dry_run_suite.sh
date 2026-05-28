#!/usr/bin/env zsh
#
# 维护注释：stage447 focused suite 消费 stage446 recovery demo surface action packet，
# 验证 demo surface action intent 能进入 owner-local state update dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE447_TMPDIR:-/tmp/cjgui-stage447-transaction-visibility-recovery-demo-surface-action-state-update-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage447-transaction-visibility-recovery-demo-surface-action-state-update-dry-run-suite.packet"
STAGE446_SUITE_PACKET="${CJGUI_STAGE447_INPUT_PACKET:-${CJGUI_STAGE446_TRANSACTION_VISIBILITY_RECOVERY_DEMO_SURFACE_INPUT_EVENT_ACTION_ADAPTER_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage447-transaction-visibility-recovery-demo-surface-action-state-update-dry-run-owner.log"

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
    echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_consumed=true" \
  "owner_local_transaction_visibility_recovery_action_intent_consumed=true" \
  "transaction_visibility_recovery_demo_surface_input_event_adapter_consumed=true" \
  "transaction_visibility_recovery_demo_surface_semantic_component_projection_consumed=true" \
  "transaction_visibility_recovery_demo_surface_action_state_update_dry_run_materialized=true" \
  "todo_transaction_visibility_recovery_demo_surface_state_update_candidate_materialized=true" \
  "settings_transaction_visibility_recovery_demo_surface_state_update_candidate_materialized=true" \
  "ai_generated_settings_transaction_visibility_recovery_demo_surface_state_update_candidate_materialized=true" \
  "transaction_visibility_recovery_demo_surface_action_intent_to_state_update_dry_run_bound=true" \
  "stage445_semantic_projection_to_recovery_state_update_candidate_bound=true" \
  "transaction_visibility_recovery_demo_surface_action_rollback_preview_materialized=true" \
  "transaction_visibility_recovery_demo_surface_state_update_dry_run_only=true" \
  "stage448_transaction_visibility_recovery_demo_surface_state_update_render_command_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE446_SUITE_PACKET" || ! -f "$STAGE446_SUITE_PACKET" ]]; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: missing stage446 packet; set CJGUI_STAGE447_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_suite_version=1" \
  "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_consumed=true" \
  "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed_transitively=true" \
  "stage443_transaction_visibility_recovery_action_state_update_dry_run_consumed_transitively=true" \
  "stage442_transaction_visibility_result_recovery_action_adapter_consumed_transitively=true" \
  "stage441_transaction_visibility_result_demo_surface_refresh_consumed_transitively=true" \
  "stage440_transaction_visibility_not_published_result_boundary_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "transaction_visibility_recovery_demo_surface_input_event_adapter_materialized=true" \
  "owner_local_transaction_visibility_recovery_action_intent_materialized=true" \
  "transaction_visibility_recovery_input_event_adapter_bound_to_stage445_demo_surface=true" \
  "transaction_visibility_recovery_action_intent_non_dispatching=true" \
  "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_prepared=true" \
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
  require_file_fact "$STAGE446_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: runtime package build failed" >&2
  echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage446_next_route="$(fact_value "$STAGE446_SUITE_PACKET" "next_route")"

{
  echo "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_suite_version=1"
  echo "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_suite_packet=$STAGE446_SUITE_PACKET"
  echo "stage446_next_route=$stage446_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_owner_passed=true"
  echo "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_consumed=true"
  echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_consumed_transitively=true"
  echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed_transitively=true"
  echo "stage443_transaction_visibility_recovery_action_state_update_dry_run_consumed_transitively=true"
  echo "stage442_transaction_visibility_result_recovery_action_adapter_consumed_transitively=true"
  echo "stage441_transaction_visibility_result_demo_surface_refresh_consumed_transitively=true"
  echo "stage440_transaction_visibility_not_published_result_boundary_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "owner_local_transaction_visibility_recovery_action_intent_consumed=true"
  echo "transaction_visibility_recovery_demo_surface_input_event_adapter_consumed=true"
  echo "transaction_visibility_recovery_demo_surface_semantic_component_projection_consumed=true"
  echo "transaction_visibility_recovery_demo_surface_action_state_update_dry_run_materialized=true"
  echo "todo_transaction_visibility_recovery_demo_surface_state_update_candidate_materialized=true"
  echo "settings_transaction_visibility_recovery_demo_surface_state_update_candidate_materialized=true"
  echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_state_update_candidate_materialized=true"
  echo "transaction_visibility_recovery_demo_surface_action_intent_to_state_update_dry_run_bound=true"
  echo "stage445_semantic_projection_to_recovery_state_update_candidate_bound=true"
  echo "transaction_visibility_recovery_demo_surface_action_rollback_preview_materialized=true"
  echo "transaction_visibility_recovery_demo_surface_state_update_dry_run_only=true"
  echo "stage448_transaction_visibility_recovery_demo_surface_state_update_render_command_refresh_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage447_public_foreign_scan_passed=true"
  echo "stage447_forbidden_native_render_token_scan_passed=true"
  echo "stage447_protected_path_scan_passed=true"
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
  echo "next_route=stage448_transaction_visibility_recovery_demo_surface_state_update_render_command_refresh_after_stage447"
  echo "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: route_classification=transaction_visibility_recovery_demo_surface_action_state_update_dry_run_ready"
echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: consumed_stage446=true"
echo "cjgui stage447 transaction visibility recovery demo surface action state update dry run suite: state_update_committed=false"
