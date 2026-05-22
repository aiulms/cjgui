#!/usr/bin/env zsh
#
# 维护注释：stage393 focused suite 消费 stage392 activation result refresh packet，
# 验证 shared activation executor helper 可以统一 keyboard/pointer activation preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE393_TMPDIR:-/tmp/cjgui-stage393-shared-activation-executor-helper-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage393-shared-activation-executor-helper-suite.packet"
STAGE392_SUITE_PACKET="${CJGUI_STAGE393_INPUT_PACKET:-${CJGUI_STAGE392_SHARED_ACTIVATION_EXECUTOR_INPUT_PACKET:-${CJGUI_STAGE392_KEYBOARD_ACTIVATION_RESULT_RENDER_REFRESH_DEMO_PROBE_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage393_shared_activation_executor_helper_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage393_shared_activation_executor_helper.cj"
OWNER_LOG="$TMP_DIR/stage393-shared-activation-executor-helper-owner.log"

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
    echo "cjgui stage393 shared activation executor helper suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage393 shared activation executor helper suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage393 shared activation executor helper suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage393 shared activation executor helper suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage393 shared activation executor helper suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage392_keyboard_activation_result_render_refresh_demo_probe_consumed=true" \
  "shared_activation_executor_helper_materialized=true" \
  "keyboard_activation_result_path_unified=true" \
  "pointer_activation_intent_path_unified=true" \
  "todo_activation_bound_to_shared_executor=true" \
  "settings_activation_bound_to_shared_executor=true" \
  "ai_generated_settings_activation_bound_to_shared_executor=true" \
  "shared_activation_owner_acceptance_gate_materialized=true" \
  "shared_activation_accepted_result_preview_materialized=true" \
  "shared_activation_rejected_rollback_preview_materialized=true" \
  "shared_activation_state_delta_preview_materialized=true" \
  "shared_activation_executor_bound_to_stage383_render_bridge=true" \
  "shared_activation_executor_bound_to_stage392_result_refresh=true" \
  "shared_activation_executor_preview_only=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE392_SUITE_PACKET" || ! -f "$STAGE392_SUITE_PACKET" ]]; then
  echo "cjgui stage393 shared activation executor helper suite: missing stage392 packet; set CJGUI_STAGE393_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage392_keyboard_activation_result_render_refresh_demo_probe_suite_version=1" \
  "stage391_keyboard_activation_action_dry_run_consumed=true" \
  "stage390_focus_traversal_render_refresh_demo_probe_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "keyboard_activation_result_envelope_materialized=true" \
  "accepted_activation_result_preview_materialized=true" \
  "rejected_activation_rollback_preview_materialized=true" \
  "activation_result_bound_to_todo_surface_refresh=true" \
  "activation_result_bound_to_settings_surface_refresh=true" \
  "activation_result_bound_to_focus_ring_refresh=true" \
  "keyboard_activation_render_command_refresh_plan_materialized=true" \
  "activation_refresh_bound_to_stage383_render_bridge=true" \
  "activation_refresh_bound_to_stage391_action_dry_run=true" \
  "keyboard_activation_result_render_refresh_preview_only=true" \
  "stage393_shared_activation_executor_helper_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE392_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage393 shared activation executor helper suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage393 shared activation executor helper suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage393 shared activation executor helper suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage393 shared activation executor helper suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage393 shared activation executor helper suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage393 shared activation executor helper suite: runtime package build failed" >&2
  echo "cjgui stage393 shared activation executor helper suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage392_next_route="$(fact_value "$STAGE392_SUITE_PACKET" "next_route")"

{
  echo "stage393_shared_activation_executor_helper_suite_version=1"
  echo "stage392_keyboard_activation_result_render_refresh_demo_probe_suite_packet=$STAGE392_SUITE_PACKET"
  echo "stage392_next_route=$stage392_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage393_shared_activation_executor_helper_owner_passed=true"
  echo "stage392_keyboard_activation_result_render_refresh_demo_probe_consumed=true"
  echo "stage391_keyboard_activation_action_dry_run_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_activation_executor_helper_materialized=true"
  echo "keyboard_activation_result_path_unified=true"
  echo "pointer_activation_intent_path_unified=true"
  echo "todo_activation_bound_to_shared_executor=true"
  echo "settings_activation_bound_to_shared_executor=true"
  echo "ai_generated_settings_activation_bound_to_shared_executor=true"
  echo "shared_activation_owner_acceptance_gate_materialized=true"
  echo "shared_activation_accepted_result_preview_materialized=true"
  echo "shared_activation_rejected_rollback_preview_materialized=true"
  echo "shared_activation_state_delta_preview_materialized=true"
  echo "shared_activation_executor_bound_to_stage383_render_bridge=true"
  echo "shared_activation_executor_bound_to_stage392_result_refresh=true"
  echo "shared_activation_executor_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage393_public_foreign_scan_passed=true"
  echo "stage393_forbidden_native_render_token_scan_passed=true"
  echo "stage393_protected_path_scan_passed=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "shared_activation_executor_dry_run=true"
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
  echo "stage394_shared_activation_executor_demo_refresh_helper_prepared=true"
  echo "next_route=stage394_shared_activation_executor_demo_refresh_helper_after_stage393"
  echo "stage393_shared_activation_executor_helper_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage393 shared activation executor helper suite: route_classification=shared_activation_executor_helper_ready"
echo "cjgui stage393 shared activation executor helper suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage393 shared activation executor helper suite: consumed_stage392=true"
echo "cjgui stage393 shared activation executor helper suite: renderer_state_write=false"
