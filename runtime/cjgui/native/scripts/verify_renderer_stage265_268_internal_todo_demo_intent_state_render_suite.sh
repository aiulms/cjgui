#!/usr/bin/env zsh
#
# 维护注释：stage265-268 focused suite 串联 Todo intent packet、state update dry-run、
# render command preview 与 readiness decision。输入是 stage264 suite packet。
# 输出仍不执行 action dispatch、不提交 state、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE265_268_TMPDIR:-/tmp/cjgui-stage265-268-internal-todo-demo-intent-state-render-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE264_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage261_264_internal_component_demo_loop_dry_run_probe_suite.sh"
STAGE264_LOG="$TMP_DIR/stage264.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage268-internal-todo-demo-readiness-decision-suite.packet"
STAGE264_SUITE_PACKET="${CJGUI_STAGE264_INTERNAL_COMPONENT_DEMO_LOOP_DRY_RUN_PROBE_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE264_REGEN="${CJGUI_STAGE265_268_ALLOW_SLOW_STAGE264_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage265_internal_todo_demo_intent_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage266_internal_todo_demo_state_update_dry_run_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage267_internal_todo_demo_render_command_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage268_internal_todo_demo_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage265_internal_todo_demo_intent_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage266_internal_todo_demo_state_update_dry_run.cj"
  "$ROOT_DIR/src/runtime_renderer_stage267_internal_todo_demo_render_command_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage268_internal_todo_demo_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE264_LOG"
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
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE264_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: owner probe failed $script" >&2
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_todo_demo_intent_packet_materialized=true"
require_file_fact "${owner_logs[2]}" "todo_demo_owner_local_state_snapshot_materialized=true"
require_file_fact "${owner_logs[3]}" "todo_list_semantic_node_preview_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_todo_demo_readiness_decision_materialized=true"

if [[ -n "$STAGE264_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE264_SUITE_PACKET" ]]; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: provided stage264 packet missing $STAGE264_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage264_suite_packet_used=true"
    echo "stage264_suite_packet_path=$STAGE264_SUITE_PACKET"
  } > "$STAGE264_LOG"
elif [[ "$ALLOW_STAGE264_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE261_264_TMPDIR="$TMP_DIR/stage261-264" \
    CJGUI_STAGE261_264_ALLOW_SLOW_STAGE260_REGEN=true \
    zsh "$STAGE264_SUITE_SCRIPT" > "$STAGE264_LOG" 2>&1; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: stage261-264 suite failed" >&2
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: log=$STAGE264_LOG" >&2
    exit 8
  fi
  STAGE264_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE264_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage265-268 internal todo demo intent/state/render suite: missing stage264 packet; set CJGUI_STAGE264_INTERNAL_COMPONENT_DEMO_LOOP_DRY_RUN_PROBE_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE265_268_ALLOW_SLOW_STAGE264_REGEN=true" >&2
  exit 7
fi

stage264_packet="$STAGE264_SUITE_PACKET"
if [[ -z "$stage264_packet" || ! -f "$stage264_packet" ]]; then
  echo "cjgui stage265-268 internal todo demo intent/state/render suite: missing stage264 packet" >&2
  exit 9
fi
for fact in \
  "stage261_264_internal_component_demo_loop_dry_run_probe_suite_passed=true" \
  "internal_component_demo_loop_dry_run_probe_readiness_decision_materialized=true" \
  "stage265_internal_todo_demo_intent_packet_input_prepared=true" \
  "internal_component_demo_loop_dry_run_probe_result_envelope_materialized=true" \
  "dry_run_probe_bound_to_action_intent_facts=true" \
  "dry_run_probe_bound_to_state_update_delta=true" \
  "dry_run_probe_bound_to_render_command_delta=true" \
  "dry_run_probe_bound_to_rollback_ready_boundary=true" \
  "dry_run_result_visibility_not_published=true" \
  "backend_ready_truth=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage264_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage265-268 internal todo demo intent/state/render suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage265-268 internal todo demo intent/state/render suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage265-268 internal todo demo intent/state/render suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage265-268 internal todo demo intent/state/render suite: runtime package build failed" >&2
  echo "cjgui stage265-268 internal todo demo intent/state/render suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage264_route="$(fact_value "$stage264_packet" "next_route")"

{
  echo "stage265_268_internal_todo_demo_intent_state_render_suite_version=1"
  echo "stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_suite_packet=$stage264_packet"
  echo "stage264_next_route=$stage264_route"
  echo "build_log=$BUILD_LOG"
  echo "stage265_internal_todo_demo_intent_packet_owner_passed=true"
  echo "stage266_internal_todo_demo_state_update_dry_run_owner_passed=true"
  echo "stage267_internal_todo_demo_render_command_preview_owner_passed=true"
  echo "stage268_internal_todo_demo_readiness_decision_owner_passed=true"
  echo "stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_consumed=true"
  echo "internal_todo_demo_intent_packet_materialized=true"
  echo "todo_add_intent_semantic_node_materialized=true"
  echo "todo_toggle_intent_semantic_node_materialized=true"
  echo "todo_remove_intent_semantic_node_materialized=true"
  echo "todo_intent_packet_bound_to_owner_local_state_delta_input=true"
  echo "todo_intent_packet_bound_to_render_command_refresh_requirement=true"
  echo "stage266_todo_demo_state_update_dry_run_input_prepared=true"
  echo "todo_demo_owner_local_state_snapshot_materialized=true"
  echo "todo_add_state_delta_dry_run_materialized=true"
  echo "todo_toggle_state_delta_dry_run_materialized=true"
  echo "todo_remove_state_delta_dry_run_materialized=true"
  echo "todo_state_delta_bound_to_rollback_ready_boundary=true"
  echo "todo_state_update_dry_run_in_memory_only=true"
  echo "stage267_todo_demo_render_command_preview_input_prepared=true"
  echo "todo_list_semantic_node_preview_materialized=true"
  echo "todo_item_semantic_node_preview_materialized=true"
  echo "todo_text_input_semantic_node_preview_materialized=true"
  echo "todo_button_semantic_node_preview_materialized=true"
  echo "todo_render_preview_bound_to_state_delta_dry_run=true"
  echo "todo_render_preview_bound_to_render_command_refresh_requirement=true"
  echo "stage268_todo_demo_readiness_decision_input_prepared=true"
  echo "internal_todo_demo_readiness_decision_materialized=true"
  echo "todo_demo_intent_state_render_joined=true"
  echo "stage269_internal_todo_demo_probe_input_prepared=true"
  echo "minimal_ui_framework_todo_demo_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage265_268_public_foreign_scan_passed=true"
  echo "stage265_268_forbidden_native_render_token_scan_passed=true"
  echo "stage265_268_protected_path_scan_passed=true"
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
  echo "next_route=stage269_internal_todo_demo_probe_input_after_todo_readiness_decision"
  echo "stage265_268_internal_todo_demo_intent_state_render_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage265-268 internal todo demo intent/state/render suite: route_classification=stage268_internal_todo_demo_readiness_decision_ready"
echo "cjgui stage265-268 internal todo demo intent/state/render suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage265-268 internal todo demo intent/state/render suite: stage269_internal_todo_demo_probe_input_prepared=true"
echo "cjgui stage265-268 internal todo demo intent/state/render suite: renderer_state_write=false"
