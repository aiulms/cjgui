#!/usr/bin/env zsh
#
# 维护注释：stage437 focused suite 消费 stage436 transaction packet，
# 验证 transaction dry-run 能进入 owner-local visibility admission / denial candidate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE437_TMPDIR:-/tmp/cjgui-stage437-transaction-visibility-render-command-transaction-admission-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage437-transaction-visibility-render-command-transaction-admission-suite.packet"
STAGE436_SUITE_PACKET="${CJGUI_STAGE437_INPUT_PACKET:-${CJGUI_STAGE436_TRANSACTION_VISIBILITY_RENDER_COMMAND_GATE_TRANSACTION_DRY_RUN_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage437_transaction_visibility_render_command_transaction_admission_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage437_transaction_visibility_render_command_transaction_admission.cj"
OWNER_LOG="$TMP_DIR/stage437-transaction-visibility-render-command-transaction-admission-owner.log"

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
    echo "cjgui stage437 transaction visibility render command transaction admission suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage437 transaction visibility render command transaction admission suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage436_transaction_visibility_render_command_gate_transaction_dry_run_consumed=true" \
  "transaction_visibility_render_command_transaction_dry_run_consumed=true" \
  "accepted_gate_to_pending_transaction_visibility_render_command_transaction_consumed=true" \
  "blocked_gate_to_rollback_transaction_visibility_render_command_transaction_consumed=true" \
  "transaction_visibility_render_command_transaction_admission_materialized=true" \
  "todo_transaction_visibility_render_command_transaction_admission_materialized=true" \
  "settings_transaction_visibility_render_command_transaction_admission_materialized=true" \
  "ai_generated_settings_transaction_visibility_render_command_transaction_admission_materialized=true" \
  "accepted_transaction_visibility_render_command_transaction_admission_candidate_prepared=true" \
  "blocked_transaction_visibility_render_command_transaction_denial_candidate_prepared=true" \
  "transaction_visibility_admission_bound_to_stage436_transaction_dry_run=true" \
  "transaction_visibility_admission_bound_to_stage435_gate=true" \
  "transaction_visibility_render_command_transaction_admission_owner_local=true" \
  "transaction_visibility_render_command_transaction_admission_preview_only=true" \
  "stage438_transaction_visibility_command_plan_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE436_SUITE_PACKET" || ! -f "$STAGE436_SUITE_PACKET" ]]; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: missing stage436 packet; set CJGUI_STAGE437_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage436_transaction_visibility_render_command_gate_transaction_dry_run_suite_version=1" \
  "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_consumed=true" \
  "stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run_consumed_transitively=true" \
  "stage433_transaction_visibility_state_update_render_command_refresh_consumed_transitively=true" \
  "stage432_transaction_visibility_action_intent_state_update_dry_run_consumed_transitively=true" \
  "stage431_transaction_visibility_preview_input_event_action_adapter_consumed_transitively=true" \
  "stage430_transaction_visibility_preview_diff_render_command_refresh_consumed_transitively=true" \
  "stage429_demo_surface_transaction_visibility_preview_refresh_consumed_transitively=true" \
  "stage428_render_command_transaction_visibility_command_plan_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "transaction_visibility_render_command_refresh_owner_acceptance_gate_consumed=true" \
  "accepted_transaction_visibility_render_command_gate_candidate_consumed=true" \
  "blocked_transaction_visibility_render_command_rollback_candidate_consumed=true" \
  "transaction_visibility_render_command_transaction_dry_run_materialized=true" \
  "todo_transaction_visibility_render_command_transaction_dry_run_materialized=true" \
  "settings_transaction_visibility_render_command_transaction_dry_run_materialized=true" \
  "ai_generated_settings_transaction_visibility_render_command_transaction_dry_run_materialized=true" \
  "accepted_gate_to_pending_transaction_visibility_render_command_transaction_mapped=true" \
  "blocked_gate_to_rollback_transaction_visibility_render_command_transaction_mapped=true" \
  "transaction_dry_run_bound_to_stage435_gate=true" \
  "transaction_dry_run_bound_to_stage434_demo_surface_batch=true" \
  "transaction_visibility_render_command_transaction_owner_local=true" \
  "transaction_visibility_render_command_transaction_preview_only=true" \
  "stage437_transaction_visibility_render_command_transaction_admission_prepared=true" \
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
  require_file_fact "$STAGE436_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage437 transaction visibility render command transaction admission suite: runtime package build failed" >&2
  echo "cjgui stage437 transaction visibility render command transaction admission suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage436_next_route="$(fact_value "$STAGE436_SUITE_PACKET" "next_route")"

{
  echo "stage437_transaction_visibility_render_command_transaction_admission_suite_version=1"
  echo "stage436_transaction_visibility_render_command_gate_transaction_dry_run_suite_packet=$STAGE436_SUITE_PACKET"
  echo "stage436_next_route=$stage436_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage437_transaction_visibility_render_command_transaction_admission_owner_passed=true"
  echo "stage436_transaction_visibility_render_command_gate_transaction_dry_run_consumed=true"
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
  echo "transaction_visibility_render_command_transaction_dry_run_consumed=true"
  echo "todo_transaction_visibility_render_command_transaction_dry_run_consumed=true"
  echo "settings_transaction_visibility_render_command_transaction_dry_run_consumed=true"
  echo "ai_generated_settings_transaction_visibility_render_command_transaction_dry_run_consumed=true"
  echo "accepted_gate_to_pending_transaction_visibility_render_command_transaction_consumed=true"
  echo "blocked_gate_to_rollback_transaction_visibility_render_command_transaction_consumed=true"
  echo "transaction_visibility_render_command_transaction_admission_materialized=true"
  echo "todo_transaction_visibility_render_command_transaction_admission_materialized=true"
  echo "settings_transaction_visibility_render_command_transaction_admission_materialized=true"
  echo "ai_generated_settings_transaction_visibility_render_command_transaction_admission_materialized=true"
  echo "accepted_transaction_visibility_render_command_transaction_admission_candidate_prepared=true"
  echo "blocked_transaction_visibility_render_command_transaction_denial_candidate_prepared=true"
  echo "transaction_visibility_admission_bound_to_stage436_transaction_dry_run=true"
  echo "transaction_visibility_admission_bound_to_stage435_gate=true"
  echo "transaction_visibility_render_command_transaction_admission_owner_local=true"
  echo "transaction_visibility_render_command_transaction_admission_preview_only=true"
  echo "stage438_transaction_visibility_command_plan_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage437_public_foreign_scan_passed=true"
  echo "stage437_forbidden_native_render_token_scan_passed=true"
  echo "stage437_protected_path_scan_passed=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
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
  echo "next_route=stage438_transaction_visibility_command_plan_after_stage437"
  echo "stage437_transaction_visibility_render_command_transaction_admission_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage437 transaction visibility render command transaction admission suite: route_classification=transaction_visibility_render_command_transaction_admission_ready"
echo "cjgui stage437 transaction visibility render command transaction admission suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage437 transaction visibility render command transaction admission suite: consumed_stage436=true"
echo "cjgui stage437 transaction visibility render command transaction admission suite: visibility_published=false"
