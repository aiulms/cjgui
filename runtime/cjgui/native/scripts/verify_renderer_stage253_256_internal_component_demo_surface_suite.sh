#!/usr/bin/env zsh
#
# 维护注释：stage253-256 focused suite 串联 internal component demo surface、
# surface semantic diff/explain、demo probe input 与 surface readiness decision。
# 输入是 stage252 suite packet；输出仍不执行 backend、不提交 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE253_256_TMPDIR:-/tmp/cjgui-stage253-256-internal-component-demo-surface-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE252_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage249_252_component_demo_backend_result_preview_suite.sh"
STAGE252_LOG="$TMP_DIR/stage252.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage256-component-demo-surface-readiness-decision-suite.packet"
STAGE252_SUITE_PACKET="${CJGUI_STAGE252_COMPONENT_DEMO_BACKEND_RESULT_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE252_REGEN="${CJGUI_STAGE253_256_ALLOW_SLOW_STAGE252_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage253_internal_component_demo_surface_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage254_component_demo_surface_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage255_internal_component_demo_probe_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage256_component_demo_surface_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage253_internal_component_demo_surface.cj"
  "$ROOT_DIR/src/runtime_renderer_stage254_component_demo_surface_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage255_internal_component_demo_probe_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage256_component_demo_surface_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE252_LOG"
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
    echo "cjgui stage253-256 internal component demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE252_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage253-256 internal component demo surface suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage253-256 internal component demo surface suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage253-256 internal component demo surface suite: owner probe failed $script" >&2
    echo "cjgui stage253-256 internal component demo surface suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_component_demo_surface_materialized=true"
require_file_fact "${owner_logs[2]}" "component_demo_surface_semantic_diff_materialized=true"
require_file_fact "${owner_logs[3]}" "internal_component_demo_probe_input_materialized=true"
require_file_fact "${owner_logs[4]}" "component_demo_surface_readiness_decision_materialized=true"

if [[ -n "$STAGE252_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE252_SUITE_PACKET" ]]; then
    echo "cjgui stage253-256 internal component demo surface suite: provided stage252 packet missing $STAGE252_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage252_suite_packet_used=true"
    echo "stage252_suite_packet_path=$STAGE252_SUITE_PACKET"
  } > "$STAGE252_LOG"
elif [[ "$ALLOW_STAGE252_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE249_252_TMPDIR="$TMP_DIR/stage249-252" \
    CJGUI_STAGE249_252_ALLOW_SLOW_STAGE248_REGEN=true \
    zsh "$STAGE252_SUITE_SCRIPT" > "$STAGE252_LOG" 2>&1; then
    echo "cjgui stage253-256 internal component demo surface suite: stage249-252 suite failed" >&2
    echo "cjgui stage253-256 internal component demo surface suite: log=$STAGE252_LOG" >&2
    exit 8
  fi
  STAGE252_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE252_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage253-256 internal component demo surface suite: missing stage252 packet; set CJGUI_STAGE252_COMPONENT_DEMO_BACKEND_RESULT_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE253_256_ALLOW_SLOW_STAGE252_REGEN=true" >&2
  exit 7
fi

stage252_packet="$STAGE252_SUITE_PACKET"
if [[ -z "$stage252_packet" || ! -f "$stage252_packet" ]]; then
  echo "cjgui stage253-256 internal component demo surface suite: missing stage252 packet" >&2
  exit 9
fi
for fact in \
  "stage249_252_component_demo_backend_result_suite_passed=true" \
  "component_demo_backend_result_readiness_decision_materialized=true" \
  "stage253_internal_component_demo_surface_input_prepared=true" \
  "backend_result_preview_bound_to_button_like_semantic_node=true" \
  "backend_result_preview_bound_to_refreshed_render_command=true" \
  "backend_result_preview_bound_to_executor_result=true" \
  "backend_result_state_update_bridge_materialized=true" \
  "backend_result_bound_to_component_demo_state_update_dry_run=true" \
  "backend_result_owner_local_rollback_preview_bound=true" \
  "backend_result_state_commit_rejected=true" \
  "backend_result_visibility_publication_rejected=true" \
  "backend_ready_truth=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage252_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage253-256 internal component demo surface suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage253-256 internal component demo surface suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage253-256 internal component demo surface suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage253-256 internal component demo surface suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage253-256 internal component demo surface suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage253-256 internal component demo surface suite: runtime package build failed" >&2
  echo "cjgui stage253-256 internal component demo surface suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage252_route="$(fact_value "$stage252_packet" "next_route")"

{
  echo "stage253_256_internal_component_demo_surface_suite_version=1"
  echo "stage252_component_demo_backend_result_readiness_decision_suite_packet=$stage252_packet"
  echo "stage252_next_route=$stage252_route"
  echo "build_log=$BUILD_LOG"
  echo "stage253_internal_component_demo_surface_owner_passed=true"
  echo "stage254_component_demo_surface_semantic_diff_explain_owner_passed=true"
  echo "stage255_internal_component_demo_probe_input_owner_passed=true"
  echo "stage256_component_demo_surface_readiness_decision_owner_passed=true"
  echo "stage252_component_demo_backend_result_readiness_decision_consumed=true"
  echo "internal_component_demo_surface_materialized=true"
  echo "surface_joined_with_button_like_semantic_node=true"
  echo "surface_joined_with_refreshed_render_command=true"
  echo "surface_joined_with_backend_result_preview=true"
  echo "surface_joined_with_state_update_bridge=true"
  echo "surface_owner_local_in_memory_only=true"
  echo "stage254_component_demo_surface_semantic_diff_explain_input_prepared=true"
  echo "component_demo_surface_semantic_diff_materialized=true"
  echo "component_demo_surface_explain_packet_materialized=true"
  echo "surface_diff_bound_to_backend_result_preview=true"
  echo "surface_explain_bound_to_rollback_ready_boundary=true"
  echo "surface_rollback_ready_boundary_materialized=true"
  echo "stage255_internal_component_demo_probe_input_prepared=true"
  echo "internal_component_demo_probe_input_materialized=true"
  echo "probe_input_bound_to_internal_surface=true"
  echo "probe_input_bound_to_render_command_preview=true"
  echo "probe_input_bound_to_state_update_dry_run=true"
  echo "probe_input_bound_to_action_intent_facts=true"
  echo "probe_input_non_executing=true"
  echo "stage256_component_demo_surface_readiness_decision_input_prepared=true"
  echo "component_demo_surface_readiness_decision_materialized=true"
  echo "stage257_internal_component_demo_state_render_action_loop_input_prepared=true"
  echo "minimal_ui_framework_surface_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage253_256_public_foreign_scan_passed=true"
  echo "stage253_256_forbidden_native_render_token_scan_passed=true"
  echo "stage253_256_protected_path_scan_passed=true"
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
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage257_internal_component_demo_state_render_action_loop_after_surface_readiness_decision"
  echo "stage253_256_internal_component_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage253-256 internal component demo surface suite: route_classification=stage256_component_demo_surface_readiness_decision_ready"
echo "cjgui stage253-256 internal component demo surface suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage253-256 internal component demo surface suite: stage257_internal_component_demo_state_render_action_loop_input_prepared=true"
echo "cjgui stage253-256 internal component demo surface suite: renderer_state_write=false"
