#!/usr/bin/env zsh
#
# 维护注释：stage269-272 focused suite 串联 Todo demo probe input、result envelope、
# semantic diff/explain 与 readiness decision。输入是 stage268 suite packet。
# 输出仍不执行 action dispatch、不提交 state、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE269_272_TMPDIR:-/tmp/cjgui-stage269-272-internal-todo-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE268_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage265_268_internal_todo_demo_intent_state_render_suite.sh"
STAGE268_LOG="$TMP_DIR/stage268.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage272-internal-todo-demo-probe-readiness-decision-suite.packet"
STAGE268_SUITE_PACKET="${CJGUI_STAGE268_INTERNAL_TODO_DEMO_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE268_REGEN="${CJGUI_STAGE269_272_ALLOW_SLOW_STAGE268_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage269_internal_todo_demo_probe_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage270_internal_todo_demo_probe_result_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage271_internal_todo_demo_probe_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage272_internal_todo_demo_probe_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage269_internal_todo_demo_probe_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage270_internal_todo_demo_probe_result_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage271_internal_todo_demo_probe_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage272_internal_todo_demo_probe_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE268_LOG"
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
    echo "cjgui stage269-272 internal todo demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE268_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage269-272 internal todo demo probe suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage269-272 internal todo demo probe suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage269-272 internal todo demo probe suite: owner probe failed $script" >&2
    echo "cjgui stage269-272 internal todo demo probe suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_todo_demo_probe_input_materialized=true"
require_file_fact "${owner_logs[2]}" "internal_todo_demo_probe_result_envelope_materialized=true"
require_file_fact "${owner_logs[3]}" "todo_demo_probe_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_todo_demo_probe_readiness_decision_materialized=true"

if [[ -n "$STAGE268_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE268_SUITE_PACKET" ]]; then
    echo "cjgui stage269-272 internal todo demo probe suite: provided stage268 packet missing $STAGE268_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage268_suite_packet_used=true"
    echo "stage268_suite_packet_path=$STAGE268_SUITE_PACKET"
  } > "$STAGE268_LOG"
elif [[ "$ALLOW_STAGE268_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE265_268_TMPDIR="$TMP_DIR/stage265-268" \
    CJGUI_STAGE265_268_ALLOW_SLOW_STAGE264_REGEN=true \
    zsh "$STAGE268_SUITE_SCRIPT" > "$STAGE268_LOG" 2>&1; then
    echo "cjgui stage269-272 internal todo demo probe suite: stage265-268 suite failed" >&2
    echo "cjgui stage269-272 internal todo demo probe suite: log=$STAGE268_LOG" >&2
    exit 8
  fi
  STAGE268_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE268_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage269-272 internal todo demo probe suite: missing stage268 packet; set CJGUI_STAGE268_INTERNAL_TODO_DEMO_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE269_272_ALLOW_SLOW_STAGE268_REGEN=true" >&2
  exit 7
fi

stage268_packet="$STAGE268_SUITE_PACKET"
if [[ -z "$stage268_packet" || ! -f "$stage268_packet" ]]; then
  echo "cjgui stage269-272 internal todo demo probe suite: missing stage268 packet" >&2
  exit 9
fi
for fact in \
  "stage265_268_internal_todo_demo_intent_state_render_suite_passed=true" \
  "internal_todo_demo_readiness_decision_materialized=true" \
  "stage269_internal_todo_demo_probe_input_prepared=true" \
  "internal_todo_demo_intent_packet_materialized=true" \
  "todo_add_intent_semantic_node_materialized=true" \
  "todo_toggle_intent_semantic_node_materialized=true" \
  "todo_remove_intent_semantic_node_materialized=true" \
  "todo_demo_owner_local_state_snapshot_materialized=true" \
  "todo_add_state_delta_dry_run_materialized=true" \
  "todo_toggle_state_delta_dry_run_materialized=true" \
  "todo_remove_state_delta_dry_run_materialized=true" \
  "todo_list_semantic_node_preview_materialized=true" \
  "todo_item_semantic_node_preview_materialized=true" \
  "todo_text_input_semantic_node_preview_materialized=true" \
  "todo_button_semantic_node_preview_materialized=true" \
  "todo_demo_intent_state_render_joined=true" \
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
  require_file_fact "$stage268_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage269-272 internal todo demo probe suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage269-272 internal todo demo probe suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage269-272 internal todo demo probe suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage269-272 internal todo demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage269-272 internal todo demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage269-272 internal todo demo probe suite: runtime package build failed" >&2
  echo "cjgui stage269-272 internal todo demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage268_route="$(fact_value "$stage268_packet" "next_route")"

{
  echo "stage269_272_internal_todo_demo_probe_suite_version=1"
  echo "stage268_internal_todo_demo_readiness_decision_suite_packet=$stage268_packet"
  echo "stage268_next_route=$stage268_route"
  echo "build_log=$BUILD_LOG"
  echo "stage269_internal_todo_demo_probe_input_owner_passed=true"
  echo "stage270_internal_todo_demo_probe_result_envelope_owner_passed=true"
  echo "stage271_internal_todo_demo_probe_semantic_diff_explain_owner_passed=true"
  echo "stage272_internal_todo_demo_probe_readiness_decision_owner_passed=true"
  echo "stage268_internal_todo_demo_readiness_decision_consumed=true"
  echo "internal_todo_demo_probe_input_materialized=true"
  echo "todo_probe_input_bound_to_add_intent=true"
  echo "todo_probe_input_bound_to_toggle_intent=true"
  echo "todo_probe_input_bound_to_remove_intent=true"
  echo "todo_probe_input_bound_to_owner_local_state_delta=true"
  echo "todo_probe_input_bound_to_render_command_preview=true"
  echo "todo_probe_input_bound_to_rollback_ready_boundary=true"
  echo "todo_probe_input_bound_to_visibility_not_published_boundary=true"
  echo "todo_probe_input_non_executing=true"
  echo "stage270_todo_demo_probe_result_envelope_input_prepared=true"
  echo "internal_todo_demo_probe_result_envelope_materialized=true"
  echo "todo_probe_result_envelope_bound_to_probe_input=true"
  echo "todo_probe_result_envelope_bound_to_state_update_dry_run=true"
  echo "todo_probe_result_envelope_bound_to_render_command_preview=true"
  echo "todo_probe_result_owner_local_in_memory_only=true"
  echo "todo_probe_result_rollback_ready=true"
  echo "todo_probe_result_visibility_not_published=true"
  echo "stage271_todo_demo_probe_semantic_diff_explain_input_prepared=true"
  echo "todo_demo_probe_semantic_diff_materialized=true"
  echo "todo_demo_probe_explain_packet_materialized=true"
  echo "todo_probe_diff_bound_to_intent_state_render_order=true"
  echo "todo_probe_explain_bound_to_add_toggle_remove_intents=true"
  echo "todo_probe_rollback_ready_boundary_rechecked=true"
  echo "todo_probe_visibility_not_published_boundary_rechecked=true"
  echo "stage272_todo_demo_probe_readiness_decision_input_prepared=true"
  echo "internal_todo_demo_probe_readiness_decision_materialized=true"
  echo "todo_probe_input_result_diff_joined=true"
  echo "todo_probe_rollback_visibility_boundary_joined=true"
  echo "stage273_internal_settings_panel_demo_intent_packet_input_prepared=true"
  echo "minimal_ui_framework_todo_probe_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage269_272_public_foreign_scan_passed=true"
  echo "stage269_272_forbidden_native_render_token_scan_passed=true"
  echo "stage269_272_protected_path_scan_passed=true"
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
  echo "next_route=stage273_internal_settings_panel_demo_intent_packet_after_todo_probe_readiness_decision"
  echo "stage269_272_internal_todo_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage269-272 internal todo demo probe suite: route_classification=stage272_internal_todo_demo_probe_readiness_decision_ready"
echo "cjgui stage269-272 internal todo demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage269-272 internal todo demo probe suite: stage273_internal_settings_panel_demo_intent_packet_input_prepared=true"
echo "cjgui stage269-272 internal todo demo probe suite: renderer_state_write=false"
