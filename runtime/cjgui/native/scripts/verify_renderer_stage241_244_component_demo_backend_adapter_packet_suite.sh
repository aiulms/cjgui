#!/usr/bin/env zsh
#
# 维护注释：stage241-244 focused suite 串联 component demo backend adapter
# packet、semantic diff/explain、dry-run predicate 与 readiness decision。
# 输入是 stage240 suite packet；输出仍不执行 backend、不写 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE241_244_TMPDIR:-/tmp/cjgui-stage241-244-component-demo-backend-adapter-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE240_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage237_240_backend_adapter_preview_suite.sh"
STAGE240_LOG="$TMP_DIR/stage240.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage244-component-demo-backend-adapter-readiness-decision-suite.packet"
STAGE240_SUITE_PACKET="${CJGUI_STAGE240_BACKEND_ADAPTER_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE240_REGEN="${CJGUI_STAGE241_244_ALLOW_SLOW_STAGE240_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage241_component_demo_backend_adapter_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage242_backend_adapter_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage243_backend_adapter_dry_run_predicate_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage244_component_demo_backend_adapter_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage241_component_demo_backend_adapter_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage242_backend_adapter_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage243_backend_adapter_dry_run_predicate.cj"
  "$ROOT_DIR/src/runtime_renderer_stage244_component_demo_backend_adapter_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE240_LOG"
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
    echo "cjgui stage241-244 component demo backend adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE240_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage241-244 component demo backend adapter suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage241-244 component demo backend adapter suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage241-244 component demo backend adapter suite: owner probe failed $script" >&2
    echo "cjgui stage241-244 component demo backend adapter suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "component_demo_backend_adapter_packet_materialized=true"
require_file_fact "${owner_logs[2]}" "backend_adapter_semantic_diff_materialized=true"
require_file_fact "${owner_logs[3]}" "backend_adapter_dry_run_predicate_materialized=true"
require_file_fact "${owner_logs[4]}" "component_demo_backend_adapter_readiness_decision_materialized=true"

if [[ -n "$STAGE240_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE240_SUITE_PACKET" ]]; then
    echo "cjgui stage241-244 component demo backend adapter suite: provided stage240 packet missing $STAGE240_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage240_suite_packet_used=true"
    echo "stage240_suite_packet_path=$STAGE240_SUITE_PACKET"
  } > "$STAGE240_LOG"
elif [[ "$ALLOW_STAGE240_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE237_240_TMPDIR="$TMP_DIR/stage237-240" \
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
    zsh "$STAGE240_SUITE_SCRIPT" > "$STAGE240_LOG" 2>&1; then
    echo "cjgui stage241-244 component demo backend adapter suite: stage237-240 suite failed" >&2
    echo "cjgui stage241-244 component demo backend adapter suite: log=$STAGE240_LOG" >&2
    exit 8
  fi
  STAGE240_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE240_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage241-244 component demo backend adapter suite: missing stage240 packet; set CJGUI_STAGE240_BACKEND_ADAPTER_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE241_244_ALLOW_SLOW_STAGE240_REGEN=true" >&2
  exit 7
fi

stage240_packet="$STAGE240_SUITE_PACKET"
if [[ -z "$stage240_packet" || ! -f "$stage240_packet" ]]; then
  echo "cjgui stage241-244 component demo backend adapter suite: missing stage240 packet" >&2
  exit 9
fi
for fact in \
  "stage237_240_backend_adapter_preview_suite_passed=true" \
  "minimal_backend_adapter_readiness_decision_materialized=true" \
  "stage241_component_demo_backend_adapter_packet_input_prepared=true" \
  "adapter_preview_bound_to_button_like_component_demo=true" \
  "adapter_predicate_rejects_renderer_submission=true" \
  "backend_adapter_rollback_ready_result_envelope=true" \
  "backend_adapter_visibility_not_published_boundary=true" \
  "backend_ready_truth=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage240_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage241-244 component demo backend adapter suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage241-244 component demo backend adapter suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage241-244 component demo backend adapter suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage241-244 component demo backend adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage241-244 component demo backend adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage241-244 component demo backend adapter suite: runtime package build failed" >&2
  echo "cjgui stage241-244 component demo backend adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage240_route="$(fact_value "$stage240_packet" "next_route")"

{
  echo "stage241_244_component_demo_backend_adapter_suite_version=1"
  echo "stage240_backend_adapter_readiness_decision_suite_packet=$stage240_packet"
  echo "stage240_next_route=$stage240_route"
  echo "build_log=$BUILD_LOG"
  echo "stage241_component_demo_backend_adapter_packet_owner_passed=true"
  echo "stage242_backend_adapter_semantic_diff_explain_owner_passed=true"
  echo "stage243_backend_adapter_dry_run_predicate_owner_passed=true"
  echo "stage244_component_demo_backend_adapter_readiness_decision_owner_passed=true"
  echo "stage240_backend_adapter_readiness_decision_consumed=true"
  echo "component_demo_backend_adapter_packet_materialized=true"
  echo "adapter_packet_bound_to_button_like_semantic_node=true"
  echo "adapter_packet_bound_to_refreshed_render_command=true"
  echo "adapter_packet_bound_to_no_submit_backend_adapter_readiness=true"
  echo "stage242_backend_adapter_semantic_diff_input_prepared=true"
  echo "backend_adapter_semantic_diff_materialized=true"
  echo "backend_adapter_explain_packet_materialized=true"
  echo "backend_adapter_rollback_ready_boundary_materialized=true"
  echo "stage243_backend_adapter_dry_run_predicate_input_prepared=true"
  echo "backend_adapter_dry_run_predicate_materialized=true"
  echo "owner_local_in_memory_adapter_dry_run_allowed=true"
  echo "renderer_submission_mutation_rejected=true"
  echo "renderer_state_write_mutation_rejected=true"
  echo "stage244_backend_adapter_readiness_decision_input_prepared=true"
  echo "component_demo_backend_adapter_readiness_decision_materialized=true"
  echo "stage245_backend_adapter_dry_run_executor_input_prepared=true"
  echo "minimal_ui_framework_backend_adapter_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage241_244_public_foreign_scan_passed=true"
  echo "stage241_244_forbidden_native_render_token_scan_passed=true"
  echo "stage241_244_protected_path_scan_passed=true"
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
  echo "next_route=stage245_backend_adapter_dry_run_executor_after_component_demo_backend_adapter_readiness_decision"
  echo "stage241_244_component_demo_backend_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage241-244 component demo backend adapter suite: route_classification=stage244_backend_adapter_readiness_decision_ready"
echo "cjgui stage241-244 component demo backend adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage241-244 component demo backend adapter suite: stage245_backend_adapter_dry_run_executor_input_prepared=true"
echo "cjgui stage241-244 component demo backend adapter suite: renderer_state_write=false"
