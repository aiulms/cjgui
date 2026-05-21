#!/usr/bin/env zsh
#
# 维护注释：stage245-248 focused suite 串联 backend adapter dry-run executor、
# result packet、visibility boundary recheck 与 executor readiness decision。
# 输入是 stage244 suite packet；输出仍不提交 backend、不写 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE245_248_TMPDIR:-/tmp/cjgui-stage245-248-backend-adapter-dry-run-executor-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE244_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage241_244_component_demo_backend_adapter_packet_suite.sh"
STAGE244_LOG="$TMP_DIR/stage244.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage248-backend-adapter-executor-readiness-decision-suite.packet"
STAGE244_SUITE_PACKET="${CJGUI_STAGE244_COMPONENT_DEMO_BACKEND_ADAPTER_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE244_REGEN="${CJGUI_STAGE245_248_ALLOW_SLOW_STAGE244_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage245_backend_adapter_dry_run_executor_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage246_backend_adapter_executor_result_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage247_backend_adapter_visibility_boundary_recheck_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage248_backend_adapter_executor_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage245_backend_adapter_dry_run_executor.cj"
  "$ROOT_DIR/src/runtime_renderer_stage246_backend_adapter_executor_result_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage247_backend_adapter_visibility_boundary_recheck.cj"
  "$ROOT_DIR/src/runtime_renderer_stage248_backend_adapter_executor_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE244_LOG"
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
    echo "cjgui stage245-248 backend adapter dry-run executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE244_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: owner probe failed $script" >&2
    echo "cjgui stage245-248 backend adapter dry-run executor suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "backend_adapter_dry_run_executor_materialized=true"
require_file_fact "${owner_logs[2]}" "backend_adapter_executor_result_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "backend_adapter_visibility_boundary_recheck_materialized=true"
require_file_fact "${owner_logs[4]}" "backend_adapter_executor_readiness_decision_materialized=true"

if [[ -n "$STAGE244_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE244_SUITE_PACKET" ]]; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: provided stage244 packet missing $STAGE244_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage244_suite_packet_used=true"
    echo "stage244_suite_packet_path=$STAGE244_SUITE_PACKET"
  } > "$STAGE244_LOG"
elif [[ "$ALLOW_STAGE244_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE241_244_TMPDIR="$TMP_DIR/stage241-244" \
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
    zsh "$STAGE244_SUITE_SCRIPT" > "$STAGE244_LOG" 2>&1; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: stage241-244 suite failed" >&2
    echo "cjgui stage245-248 backend adapter dry-run executor suite: log=$STAGE244_LOG" >&2
    exit 8
  fi
  STAGE244_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE244_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage245-248 backend adapter dry-run executor suite: missing stage244 packet; set CJGUI_STAGE244_COMPONENT_DEMO_BACKEND_ADAPTER_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE245_248_ALLOW_SLOW_STAGE244_REGEN=true" >&2
  exit 7
fi

stage244_packet="$STAGE244_SUITE_PACKET"
if [[ -z "$stage244_packet" || ! -f "$stage244_packet" ]]; then
  echo "cjgui stage245-248 backend adapter dry-run executor suite: missing stage244 packet" >&2
  exit 9
fi
for fact in \
  "stage241_244_component_demo_backend_adapter_suite_passed=true" \
  "component_demo_backend_adapter_readiness_decision_materialized=true" \
  "stage245_backend_adapter_dry_run_executor_input_prepared=true" \
  "owner_local_in_memory_adapter_dry_run_allowed=true" \
  "renderer_submission_mutation_rejected=true" \
  "renderer_state_write_mutation_rejected=true" \
  "backend_ready_truth=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage244_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage245-248 backend adapter dry-run executor suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage245-248 backend adapter dry-run executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage245-248 backend adapter dry-run executor suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage245-248 backend adapter dry-run executor suite: runtime package build failed" >&2
  echo "cjgui stage245-248 backend adapter dry-run executor suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage244_route="$(fact_value "$stage244_packet" "next_route")"

{
  echo "stage245_248_backend_adapter_dry_run_executor_suite_version=1"
  echo "stage244_component_demo_backend_adapter_readiness_decision_suite_packet=$stage244_packet"
  echo "stage244_next_route=$stage244_route"
  echo "build_log=$BUILD_LOG"
  echo "stage245_backend_adapter_dry_run_executor_owner_passed=true"
  echo "stage246_backend_adapter_executor_result_packet_owner_passed=true"
  echo "stage247_backend_adapter_visibility_boundary_recheck_owner_passed=true"
  echo "stage248_backend_adapter_executor_readiness_decision_owner_passed=true"
  echo "stage244_component_demo_backend_adapter_readiness_decision_consumed=true"
  echo "backend_adapter_dry_run_executor_materialized=true"
  echo "executor_bound_to_component_demo_backend_adapter_readiness=true"
  echo "executor_bound_to_owner_local_dry_run_predicate=true"
  echo "owner_local_in_memory_adapter_dry_run_executed=true"
  echo "backend_adapter_executor_no_submit=true"
  echo "backend_adapter_executor_rollback_snapshot_captured=true"
  echo "stage246_backend_adapter_executor_result_packet_input_prepared=true"
  echo "backend_adapter_executor_result_packet_materialized=true"
  echo "backend_adapter_executor_result_bound_to_rollback_ready_envelope=true"
  echo "backend_adapter_executor_result_owner_local_in_memory_only=true"
  echo "executor_result_renderer_submission_rejected=true"
  echo "executor_result_renderer_state_write_rejected=true"
  echo "stage247_backend_adapter_visibility_boundary_recheck_input_prepared=true"
  echo "backend_adapter_visibility_boundary_recheck_materialized=true"
  echo "backend_adapter_visibility_not_published_boundary_rechecked=true"
  echo "backend_adapter_executor_result_rollback_ready_rechecked=true"
  echo "visibility_publication_admitted=false"
  echo "stage248_backend_adapter_executor_readiness_decision_input_prepared=true"
  echo "backend_adapter_executor_joined_with_result_packet_and_visibility_boundary=true"
  echo "backend_adapter_executor_readiness_decision_materialized=true"
  echo "stage249_component_demo_backend_result_preview_input_prepared=true"
  echo "minimal_ui_framework_backend_adapter_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage245_248_public_foreign_scan_passed=true"
  echo "stage245_248_forbidden_native_render_token_scan_passed=true"
  echo "stage245_248_protected_path_scan_passed=true"
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
  echo "next_route=stage249_component_demo_backend_result_preview_after_executor_readiness_decision"
  echo "stage245_248_backend_adapter_dry_run_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage245-248 backend adapter dry-run executor suite: route_classification=stage248_backend_adapter_executor_readiness_decision_ready"
echo "cjgui stage245-248 backend adapter dry-run executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage245-248 backend adapter dry-run executor suite: stage249_component_demo_backend_result_preview_input_prepared=true"
echo "cjgui stage245-248 backend adapter dry-run executor suite: renderer_state_write=false"
