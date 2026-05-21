#!/usr/bin/env zsh
#
# 维护注释：stage261-264 focused suite 串联 internal component demo loop dry-run probe、
# reusable result envelope、semantic diff/explain 与 readiness decision。
# 输入是 stage260 suite packet；输出仍不执行 action dispatch、不提交 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE261_264_TMPDIR:-/tmp/cjgui-stage261-264-internal-component-demo-loop-dry-run-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE260_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage257_260_internal_component_demo_loop_suite.sh"
STAGE260_LOG="$TMP_DIR/stage260.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage264-internal-component-demo-loop-dry-run-probe-readiness-decision-suite.packet"
STAGE260_SUITE_PACKET="${CJGUI_STAGE260_INTERNAL_COMPONENT_DEMO_LOOP_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE260_REGEN="${CJGUI_STAGE261_264_ALLOW_SLOW_STAGE260_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage261_internal_component_demo_loop_dry_run_probe_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage262_internal_component_demo_loop_dry_run_result_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage263_internal_component_demo_loop_dry_run_probe_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage261_internal_component_demo_loop_dry_run_probe.cj"
  "$ROOT_DIR/src/runtime_renderer_stage262_internal_component_demo_loop_dry_run_result_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage263_internal_component_demo_loop_dry_run_probe_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage264_internal_component_demo_loop_dry_run_probe_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE260_LOG"
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
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE260_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: owner probe failed $script" >&2
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_component_demo_loop_dry_run_probe_input_materialized=true"
require_file_fact "${owner_logs[2]}" "reusable_component_demo_loop_dry_run_result_envelope_materialized=true"
require_file_fact "${owner_logs[3]}" "internal_component_demo_loop_dry_run_probe_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_component_demo_loop_dry_run_probe_readiness_decision_materialized=true"

if [[ -n "$STAGE260_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE260_SUITE_PACKET" ]]; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: provided stage260 packet missing $STAGE260_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage260_suite_packet_used=true"
    echo "stage260_suite_packet_path=$STAGE260_SUITE_PACKET"
  } > "$STAGE260_LOG"
elif [[ "$ALLOW_STAGE260_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE257_260_TMPDIR="$TMP_DIR/stage257-260" \
    CJGUI_STAGE257_260_ALLOW_SLOW_STAGE256_REGEN=true \
    zsh "$STAGE260_SUITE_SCRIPT" > "$STAGE260_LOG" 2>&1; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: stage257-260 suite failed" >&2
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: log=$STAGE260_LOG" >&2
    exit 8
  fi
  STAGE260_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE260_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage261-264 internal component demo loop dry-run probe suite: missing stage260 packet; set CJGUI_STAGE260_INTERNAL_COMPONENT_DEMO_LOOP_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE261_264_ALLOW_SLOW_STAGE260_REGEN=true" >&2
  exit 7
fi

stage260_packet="$STAGE260_SUITE_PACKET"
if [[ -z "$stage260_packet" || ! -f "$stage260_packet" ]]; then
  echo "cjgui stage261-264 internal component demo loop dry-run probe suite: missing stage260 packet" >&2
  exit 9
fi
for fact in \
  "stage257_260_internal_component_demo_loop_suite_passed=true" \
  "internal_component_demo_loop_readiness_decision_materialized=true" \
  "stage261_internal_component_demo_loop_dry_run_probe_input_prepared=true" \
  "internal_component_demo_loop_semantic_diff_materialized=true" \
  "internal_component_demo_loop_explain_packet_materialized=true" \
  "loop_rollback_ready_boundary_materialized=true" \
  "loop_visibility_not_published_boundary_materialized=true" \
  "demo_loop_bound_to_action_intent_facts=true" \
  "demo_loop_bound_to_owner_local_state_update_dry_run=true" \
  "demo_loop_bound_to_refreshed_render_command=true" \
  "loop_transition_order_action_state_render=true" \
  "loop_transition_carries_state_update_dry_run_delta=true" \
  "loop_transition_carries_render_command_refresh_delta=true" \
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
  require_file_fact "$stage260_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage261-264 internal component demo loop dry-run probe suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage261-264 internal component demo loop dry-run probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage261-264 internal component demo loop dry-run probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage261-264 internal component demo loop dry-run probe suite: runtime package build failed" >&2
  echo "cjgui stage261-264 internal component demo loop dry-run probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage260_route="$(fact_value "$stage260_packet" "next_route")"

{
  echo "stage261_264_internal_component_demo_loop_dry_run_probe_suite_version=1"
  echo "stage260_internal_component_demo_loop_readiness_decision_suite_packet=$stage260_packet"
  echo "stage260_next_route=$stage260_route"
  echo "build_log=$BUILD_LOG"
  echo "stage261_internal_component_demo_loop_dry_run_probe_owner_passed=true"
  echo "stage262_internal_component_demo_loop_dry_run_result_envelope_owner_passed=true"
  echo "stage263_internal_component_demo_loop_dry_run_probe_semantic_diff_explain_owner_passed=true"
  echo "stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_owner_passed=true"
  echo "stage260_internal_component_demo_loop_readiness_decision_consumed=true"
  echo "internal_component_demo_loop_dry_run_probe_input_materialized=true"
  echo "internal_component_demo_loop_dry_run_probe_result_envelope_materialized=true"
  echo "dry_run_probe_bound_to_action_intent_facts=true"
  echo "dry_run_probe_bound_to_state_update_delta=true"
  echo "dry_run_probe_bound_to_render_command_delta=true"
  echo "dry_run_probe_bound_to_rollback_ready_boundary=true"
  echo "dry_run_probe_non_executing=true"
  echo "stage262_loop_dry_run_result_envelope_input_prepared=true"
  echo "reusable_component_demo_loop_dry_run_result_envelope_materialized=true"
  echo "dry_run_result_envelope_bound_to_probe_input=true"
  echo "dry_run_result_envelope_bound_to_probe_result=true"
  echo "dry_run_result_envelope_owner_local_in_memory_only=true"
  echo "dry_run_result_rollback_ready=true"
  echo "dry_run_result_visibility_not_published=true"
  echo "stage263_loop_dry_run_probe_semantic_diff_explain_input_prepared=true"
  echo "internal_component_demo_loop_dry_run_probe_semantic_diff_materialized=true"
  echo "internal_component_demo_loop_dry_run_probe_explain_packet_materialized=true"
  echo "dry_run_probe_diff_bound_to_result_envelope=true"
  echo "dry_run_probe_explain_bound_to_action_state_render_order=true"
  echo "dry_run_probe_rollback_ready_boundary_rechecked=true"
  echo "dry_run_probe_visibility_not_published_boundary_rechecked=true"
  echo "stage264_loop_dry_run_probe_readiness_decision_input_prepared=true"
  echo "internal_component_demo_loop_dry_run_probe_readiness_decision_materialized=true"
  echo "stage265_internal_todo_demo_intent_packet_input_prepared=true"
  echo "minimal_ui_framework_demo_loop_probe_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage261_264_public_foreign_scan_passed=true"
  echo "stage261_264_forbidden_native_render_token_scan_passed=true"
  echo "stage261_264_protected_path_scan_passed=true"
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
  echo "next_route=stage265_internal_todo_demo_intent_packet_after_loop_dry_run_probe_readiness_decision"
  echo "stage261_264_internal_component_demo_loop_dry_run_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage261-264 internal component demo loop dry-run probe suite: route_classification=stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_ready"
echo "cjgui stage261-264 internal component demo loop dry-run probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage261-264 internal component demo loop dry-run probe suite: stage265_internal_todo_demo_intent_packet_input_prepared=true"
echo "cjgui stage261-264 internal component demo loop dry-run probe suite: renderer_state_write=false"
