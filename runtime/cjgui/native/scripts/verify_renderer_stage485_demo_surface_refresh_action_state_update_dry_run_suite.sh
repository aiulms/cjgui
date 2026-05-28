#!/usr/bin/env zsh
#
# Focused suite for stage485. It consumes stage484 action intents and verifies
# owner-local state update candidates without dispatch or commit.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE485_TMPDIR:-/tmp/cjgui-stage485-demo-surface-refresh-action-state-update-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage485-demo-surface-refresh-action-state-update-dry-run-suite.packet"
STAGE484_SUITE_PACKET="${CJGUI_STAGE485_INPUT_PACKET:-${CJGUI_STAGE484_DEMO_SURFACE_REFRESH_FOCUS_INPUT_ACTION_ADAPTER_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage485_demo_surface_refresh_action_state_update_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage485_demo_surface_refresh_action_state_update_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage485-demo-surface-refresh-action-state-update-dry-run-owner.log"

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
    echo "cjgui stage485 demo surface refresh action state update dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage484_demo_surface_refresh_focus_input_action_adapter_consumed=true" \
  "shared_demo_surface_refresh_focus_input_action_adapter_consumed=true" \
  "todo_runtime_demo_surface_refresh_focus_activation_intent_consumed=true" \
  "settings_runtime_demo_surface_refresh_toggle_focus_intent_consumed=true" \
  "ai_generated_settings_runtime_demo_surface_refresh_submit_focus_intent_consumed=true" \
  "shared_demo_surface_refresh_action_state_update_dry_run_materialized=true" \
  "todo_demo_surface_refresh_state_update_candidate_materialized=true" \
  "settings_demo_surface_refresh_state_update_candidate_materialized=true" \
  "ai_generated_settings_demo_surface_refresh_state_update_candidate_materialized=true" \
  "focus_input_action_adapter_to_state_update_dry_run_bound=true" \
  "demo_surface_refresh_state_update_owner_local=true" \
  "demo_surface_refresh_state_update_dry_run_only=true" \
  "demo_surface_refresh_state_rollback_preview_materialized=true" \
  "stage486_demo_surface_refresh_state_render_command_bridge_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE484_SUITE_PACKET" || ! -f "$STAGE484_SUITE_PACKET" ]]; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: missing stage484 packet; set CJGUI_STAGE485_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage484_demo_surface_refresh_focus_input_action_adapter_suite_version=1" \
  "stage483_demo_surface_refresh_runtime_execution_contract_consumed=true" \
  "shared_demo_surface_refresh_focus_input_action_adapter_materialized=true" \
  "todo_runtime_demo_surface_refresh_focus_activation_intent_materialized=true" \
  "settings_runtime_demo_surface_refresh_toggle_focus_intent_materialized=true" \
  "ai_generated_settings_runtime_demo_surface_refresh_submit_focus_intent_materialized=true" \
  "runtime_execution_contract_to_focus_input_action_adapter_bound=true" \
  "demo_surface_refresh_focus_input_adapter_contract_materialized=true" \
  "focus_input_action_adapter_reusable=true" \
  "focus_input_action_adapter_owner_local=true" \
  "focus_input_action_adapter_non_dispatching=true" \
  "stage485_demo_surface_refresh_action_state_update_dry_run_prepared=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE484_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: runtime package build failed" >&2
  echo "cjgui stage485 demo surface refresh action state update dry-run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage484_next_route="$(fact_value "$STAGE484_SUITE_PACKET" "next_route")"

{
  echo "stage485_demo_surface_refresh_action_state_update_dry_run_suite_version=1"
  echo "stage484_demo_surface_refresh_focus_input_action_adapter_suite_packet=$STAGE484_SUITE_PACKET"
  echo "stage484_next_route=$stage484_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage485_demo_surface_refresh_action_state_update_dry_run_owner_passed=true"
  echo "stage484_demo_surface_refresh_focus_input_action_adapter_consumed=true"
  echo "stage483_demo_surface_refresh_runtime_execution_contract_consumed_transitively=true"
  echo "stage482_demo_surface_refresh_runtime_receipt_consumed_transitively=true"
  echo "shared_demo_surface_refresh_focus_input_action_adapter_consumed=true"
  echo "todo_runtime_demo_surface_refresh_focus_activation_intent_consumed=true"
  echo "settings_runtime_demo_surface_refresh_toggle_focus_intent_consumed=true"
  echo "ai_generated_settings_runtime_demo_surface_refresh_submit_focus_intent_consumed=true"
  echo "shared_demo_surface_refresh_action_state_update_dry_run_materialized=true"
  echo "todo_demo_surface_refresh_state_update_candidate_materialized=true"
  echo "settings_demo_surface_refresh_state_update_candidate_materialized=true"
  echo "ai_generated_settings_demo_surface_refresh_state_update_candidate_materialized=true"
  echo "focus_input_action_adapter_to_state_update_dry_run_bound=true"
  echo "demo_surface_refresh_state_update_owner_local=true"
  echo "demo_surface_refresh_state_update_dry_run_only=true"
  echo "demo_surface_refresh_state_rollback_preview_materialized=true"
  echo "runtime_package_build_passed=true"
  echo "stage485_public_foreign_scan_passed=true"
  echo "stage485_forbidden_native_render_token_scan_passed=true"
  echo "stage485_protected_path_scan_passed=true"
  echo "stage486_demo_surface_refresh_state_render_command_bridge_prepared=true"
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
  echo "next_route=stage486_demo_surface_refresh_state_render_command_bridge_after_stage485"
  echo "stage485_demo_surface_refresh_action_state_update_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage485 demo surface refresh action state update dry-run suite: route_classification=demo_surface_refresh_action_state_update_dry_run_ready"
echo "cjgui stage485 demo surface refresh action state update dry-run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage485 demo surface refresh action state update dry-run suite: consumed_stage484=true"
echo "cjgui stage485 demo surface refresh action state update dry-run suite: state_update_committed=false"
