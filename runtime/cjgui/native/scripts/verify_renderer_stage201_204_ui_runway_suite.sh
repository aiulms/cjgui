#!/usr/bin/env zsh
#
# 维护注释：stage201-204 focused suite 串联 write-token reevaluation、
# Scene/RenderCommand bridge、semantic node fixture 与 component demo state-update
# dry-run。它生成 UI runway readiness packet，不做真实 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE201_204_TMPDIR:-/tmp/cjgui-stage201-204-ui-runway-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE200_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage197_200_truth_semantic_recheck_join_suite.sh"
STAGE200_LOG="$TMP_DIR/stage200.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage204-component-demo-state-update-dry-run-suite.packet"
STAGE200_SUITE_PACKET="${CJGUI_STAGE200_WRITE_READINESS_RECHECK_JOIN_SUITE_PACKET:-}"
ALLOW_STAGE200_REGEN="${CJGUI_STAGE201_204_ALLOW_SLOW_STAGE200_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage201_write_token_reevaluation_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage202_scene_render_command_bridge_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage203_semantic_node_fixture_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage204_component_demo_state_update_dry_run_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage201_write_token_reevaluation.cj"
  "$ROOT_DIR/src/runtime_renderer_stage202_scene_render_command_bridge.cj"
  "$ROOT_DIR/src/runtime_renderer_stage203_semantic_node_fixture.cj"
  "$ROOT_DIR/src/runtime_renderer_stage204_component_demo_state_update_dry_run.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE200_LOG"
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
    echo "cjgui stage201-204 UI runway suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE200_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage201-204 UI runway suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage201-204 UI runway suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage201-204 UI runway suite: owner probe failed $script" >&2
    echo "cjgui stage201-204 UI runway suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "write_token_decision_envelope_materialized=true"
require_file_fact "${owner_logs[2]}" "scene_render_command_runway_bridge_materialized=true"
require_file_fact "${owner_logs[3]}" "internal_button_like_semantic_node_materialized=true"
require_file_fact "${owner_logs[4]}" "component_demo_state_update_dry_run_materialized=true"

if [[ -n "$STAGE200_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE200_SUITE_PACKET" ]]; then
    echo "cjgui stage201-204 UI runway suite: provided stage200 packet missing $STAGE200_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage200_suite_packet_used=true"
    echo "stage200_suite_packet_path=$STAGE200_SUITE_PACKET"
  } > "$STAGE200_LOG"
elif [[ "$ALLOW_STAGE200_REGEN" == "true" ]]; then
  if ! env CJGUI_STAGE197_200_TMPDIR="$TMP_DIR/stage197-200" zsh "$STAGE200_SUITE_SCRIPT" > "$STAGE200_LOG" 2>&1; then
    echo "cjgui stage201-204 UI runway suite: stage197-200 suite failed" >&2
    echo "cjgui stage201-204 UI runway suite: log=$STAGE200_LOG" >&2
    exit 8
  fi
  STAGE200_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE200_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage201-204 UI runway suite: missing stage200 packet; set CJGUI_STAGE200_WRITE_READINESS_RECHECK_JOIN_SUITE_PACKET or CJGUI_STAGE201_204_ALLOW_SLOW_STAGE200_REGEN=true" >&2
  exit 7
fi
stage200_packet="$STAGE200_SUITE_PACKET"
if [[ -z "$stage200_packet" || ! -f "$stage200_packet" ]]; then
  echo "cjgui stage201-204 UI runway suite: missing stage200 packet" >&2
  exit 9
fi
for fact in \
  "stage197_200_truth_semantic_recheck_join_suite_passed=true" \
  "renderer_state_write_readiness_recheck_join_packet_materialized=true" \
  "write_token_reevaluation_missing_predicate_receipt_materialized=true" \
  "stage201_write_token_reevaluation_input_prepared=true" \
  "renderer_state_write_eligibility=false" \
  "result_envelope_promotion_token=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$stage200_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage201-204 UI runway suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage201-204 UI runway suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage201-204 UI runway suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage201-204 UI runway suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage201-204 UI runway suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage201-204 UI runway suite: runtime package build failed" >&2
  echo "cjgui stage201-204 UI runway suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage200_route="$(fact_value "$stage200_packet" "next_route")"

{
  echo "stage201_204_ui_runway_suite_version=1"
  echo "stage200_write_readiness_recheck_join_suite_packet=$stage200_packet"
  echo "stage200_next_route=$stage200_route"
  echo "build_log=$BUILD_LOG"
  echo "stage201_write_token_reevaluation_owner_passed=true"
  echo "stage202_scene_render_command_bridge_owner_passed=true"
  echo "stage203_semantic_node_fixture_owner_passed=true"
  echo "stage204_component_demo_state_update_dry_run_owner_passed=true"
  echo "stage200_write_readiness_recheck_join_consumed=true"
  echo "write_token_decision_envelope_materialized=true"
  echo "write_token_missing_predicate_receipt_materialized=true"
  echo "stage202_scene_render_command_bridge_input_prepared=true"
  echo "render_batching_packet_consumed=true"
  echo "scene_render_command_runway_bridge_materialized=true"
  echo "stage203_semantic_node_fixture_input_prepared=true"
  echo "internal_rect_semantic_node_materialized=true"
  echo "internal_text_semantic_node_materialized=true"
  echo "internal_button_like_semantic_node_materialized=true"
  echo "stage204_component_demo_state_update_dry_run_input_prepared=true"
  echo "component_demo_state_update_dry_run_materialized=true"
  echo "owner_local_rollback_preview_materialized=true"
  echo "visibility_not_published_boundary_materialized=true"
  echo "stage205_component_demo_render_command_admission_input_prepared=true"
  echo "minimal_ui_framework_runway_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage201_204_public_foreign_scan_passed=true"
  echo "stage201_204_forbidden_native_render_token_scan_passed=true"
  echo "stage201_204_protected_path_scan_passed=true"
  echo "renderer_state_write_token=false"
  echo "renderer_state_write_eligibility=false"
  echo "result_envelope_promotion_token=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage205_component_demo_render_command_admission_after_state_update_dry_run"
  echo "stage201_204_ui_runway_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage201-204 UI runway suite: route_classification=stage204_component_demo_state_update_dry_run_ready"
echo "cjgui stage201-204 UI runway suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage201-204 UI runway suite: minimal_ui_framework_runway_input_prepared=true"
echo "cjgui stage201-204 UI runway suite: renderer_state_write=false"
