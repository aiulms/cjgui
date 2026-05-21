#!/usr/bin/env zsh
#
# 维护注释：stage249-252 focused suite 串联 backend result preview、
# semantic diff/explain、state-update bridge 与 backend result readiness decision。
# 输入是 stage248 suite packet；输出仍不提交 backend、不写 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE249_252_TMPDIR:-/tmp/cjgui-stage249-252-component-demo-backend-result-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE248_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage245_248_backend_adapter_dry_run_executor_suite.sh"
STAGE248_LOG="$TMP_DIR/stage248.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage252-component-demo-backend-result-readiness-decision-suite.packet"
STAGE248_SUITE_PACKET="${CJGUI_STAGE248_BACKEND_ADAPTER_EXECUTOR_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE248_REGEN="${CJGUI_STAGE249_252_ALLOW_SLOW_STAGE248_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage249_component_demo_backend_result_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage250_backend_result_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage251_backend_result_state_update_bridge_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage252_component_demo_backend_result_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage249_component_demo_backend_result_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage250_backend_result_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage251_backend_result_state_update_bridge.cj"
  "$ROOT_DIR/src/runtime_renderer_stage252_component_demo_backend_result_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE248_LOG"
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
    echo "cjgui stage249-252 component demo backend result suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE248_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage249-252 component demo backend result suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage249-252 component demo backend result suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage249-252 component demo backend result suite: owner probe failed $script" >&2
    echo "cjgui stage249-252 component demo backend result suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "component_demo_backend_result_preview_materialized=true"
require_file_fact "${owner_logs[2]}" "backend_result_semantic_diff_materialized=true"
require_file_fact "${owner_logs[3]}" "backend_result_state_update_bridge_materialized=true"
require_file_fact "${owner_logs[4]}" "component_demo_backend_result_readiness_decision_materialized=true"

if [[ -n "$STAGE248_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE248_SUITE_PACKET" ]]; then
    echo "cjgui stage249-252 component demo backend result suite: provided stage248 packet missing $STAGE248_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage248_suite_packet_used=true"
    echo "stage248_suite_packet_path=$STAGE248_SUITE_PACKET"
  } > "$STAGE248_LOG"
elif [[ "$ALLOW_STAGE248_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE245_248_TMPDIR="$TMP_DIR/stage245-248" \
    CJGUI_STAGE245_248_ALLOW_SLOW_STAGE244_REGEN=true \
    CJGUI_STAGE241_244_ALLOW_SLOW_STAGE240_REGEN=true \
    CJGUI_STAGE237_240_ALLOW_SLOW_STAGE236_REGEN=true \
    CJGUI_STAGE233_236_ALLOW_SLOW_STAGE232_REGEN=true \
    CJGUI_STAGE229_232_ALLOW_SLOW_STAGE228_REGEN=true \
    CJGUI_STAGE225_228_ALLOW_SLOW_STAGE224_REGEN=true \
    CJGUI_STAGE221_224_ALLOW_SLOW_STAGE220_REGEN=true \
    CJGUI_STAGE217_220_ALLOW_SLOW_STAGE216_REGEN=true \
    CJGUI_STAGE213_216_ALLOW_SLOW_STAGE212_REGEN=true \
    CJGUI_STAGE209_212_ALLOW_SLOW_STAGE208_REGEN=true \
    CJGUI_STAGE205_208_ALLOW_SLOW_STAGE204_REGEN=true \
    CJGUI_STAGE201_204_ALLOW_SLOW_STAGE200_REGEN=true \
    zsh "$STAGE248_SUITE_SCRIPT" > "$STAGE248_LOG" 2>&1; then
    echo "cjgui stage249-252 component demo backend result suite: stage245-248 suite failed" >&2
    echo "cjgui stage249-252 component demo backend result suite: log=$STAGE248_LOG" >&2
    exit 8
  fi
  STAGE248_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE248_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage249-252 component demo backend result suite: missing stage248 packet; set CJGUI_STAGE248_BACKEND_ADAPTER_EXECUTOR_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE249_252_ALLOW_SLOW_STAGE248_REGEN=true" >&2
  exit 7
fi

stage248_packet="$STAGE248_SUITE_PACKET"
if [[ -z "$stage248_packet" || ! -f "$stage248_packet" ]]; then
  echo "cjgui stage249-252 component demo backend result suite: missing stage248 packet" >&2
  exit 9
fi
for fact in \
  "stage245_248_backend_adapter_dry_run_executor_suite_passed=true" \
  "backend_adapter_executor_readiness_decision_materialized=true" \
  "stage249_component_demo_backend_result_preview_input_prepared=true" \
  "backend_adapter_executor_result_packet_materialized=true" \
  "backend_adapter_executor_result_bound_to_rollback_ready_envelope=true" \
  "backend_adapter_executor_result_owner_local_in_memory_only=true" \
  "backend_adapter_visibility_not_published_boundary_rechecked=true" \
  "backend_adapter_executor_result_rollback_ready_rechecked=true" \
  "backend_ready_truth=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage248_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage249-252 component demo backend result suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage249-252 component demo backend result suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage249-252 component demo backend result suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage249-252 component demo backend result suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage249-252 component demo backend result suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage249-252 component demo backend result suite: runtime package build failed" >&2
  echo "cjgui stage249-252 component demo backend result suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage248_route="$(fact_value "$stage248_packet" "next_route")"

{
  echo "stage249_252_component_demo_backend_result_suite_version=1"
  echo "stage248_backend_adapter_executor_readiness_decision_suite_packet=$stage248_packet"
  echo "stage248_next_route=$stage248_route"
  echo "build_log=$BUILD_LOG"
  echo "stage249_component_demo_backend_result_preview_owner_passed=true"
  echo "stage250_backend_result_semantic_diff_explain_owner_passed=true"
  echo "stage251_backend_result_state_update_bridge_owner_passed=true"
  echo "stage252_component_demo_backend_result_readiness_decision_owner_passed=true"
  echo "stage248_backend_adapter_executor_readiness_decision_consumed=true"
  echo "component_demo_backend_result_preview_materialized=true"
  echo "backend_result_preview_bound_to_executor_result=true"
  echo "backend_result_preview_bound_to_button_like_semantic_node=true"
  echo "backend_result_preview_bound_to_refreshed_render_command=true"
  echo "backend_result_preview_owner_local_in_memory_only=true"
  echo "stage250_backend_result_semantic_diff_explain_input_prepared=true"
  echo "backend_result_semantic_diff_materialized=true"
  echo "backend_result_explain_packet_materialized=true"
  echo "backend_result_rollback_ready_boundary_materialized=true"
  echo "stage251_backend_result_state_update_bridge_input_prepared=true"
  echo "backend_result_state_update_bridge_materialized=true"
  echo "backend_result_bound_to_component_demo_state_update_dry_run=true"
  echo "backend_result_owner_local_rollback_preview_bound=true"
  echo "backend_result_state_commit_rejected=true"
  echo "backend_result_visibility_publication_rejected=true"
  echo "stage252_backend_result_readiness_decision_input_prepared=true"
  echo "component_demo_backend_result_readiness_decision_materialized=true"
  echo "stage253_internal_component_demo_surface_input_prepared=true"
  echo "minimal_ui_framework_backend_result_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage249_252_public_foreign_scan_passed=true"
  echo "stage249_252_forbidden_native_render_token_scan_passed=true"
  echo "stage249_252_protected_path_scan_passed=true"
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
  echo "next_route=stage253_internal_component_demo_surface_after_backend_result_readiness_decision"
  echo "stage249_252_component_demo_backend_result_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage249-252 component demo backend result suite: route_classification=stage252_backend_result_readiness_decision_ready"
echo "cjgui stage249-252 component demo backend result suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage249-252 component demo backend result suite: stage253_internal_component_demo_surface_input_prepared=true"
echo "cjgui stage249-252 component demo backend result suite: renderer_state_write=false"
