#!/usr/bin/env zsh
#
# 维护注释：stage221-224 focused suite 串联 state update preview 后的
# RenderCommand refresh、refreshed preview packet、semantic diff/explain 与 readiness。
# 输入是 stage220 suite packet；输出仍不提交状态、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE221_224_TMPDIR:-/tmp/cjgui-stage221-224-render-command-refresh-after-state-update-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE220_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage217_220_state_update_after_action_runway_suite.sh"
STAGE220_LOG="$TMP_DIR/stage220.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage224-render-command-refresh-readiness-decision-suite.packet"
STAGE220_SUITE_PACKET="${CJGUI_STAGE220_STATEFUL_INTERACTION_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE220_REGEN="${CJGUI_STAGE221_224_ALLOW_SLOW_STAGE220_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage221_render_command_refresh_after_state_update_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage222_refreshed_render_command_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage223_render_command_refresh_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage224_render_command_refresh_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage221_render_command_refresh_after_state_update_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage222_refreshed_render_command_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage223_render_command_refresh_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage224_render_command_refresh_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE220_LOG"
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
    echo "cjgui stage221-224 render command refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE220_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage221-224 render command refresh suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage221-224 render command refresh suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage221-224 render command refresh suite: owner probe failed $script" >&2
    echo "cjgui stage221-224 render command refresh suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "render_command_refresh_preview_materialized=true"
require_file_fact "${owner_logs[2]}" "refreshed_render_command_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "render_command_refresh_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "render_command_refresh_readiness_decision_materialized=true"

if [[ -n "$STAGE220_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE220_SUITE_PACKET" ]]; then
    echo "cjgui stage221-224 render command refresh suite: provided stage220 packet missing $STAGE220_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage220_suite_packet_used=true"
    echo "stage220_suite_packet_path=$STAGE220_SUITE_PACKET"
  } > "$STAGE220_LOG"
elif [[ "$ALLOW_STAGE220_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE217_220_TMPDIR="$TMP_DIR/stage217-220" \
    CJGUI_STAGE217_220_ALLOW_SLOW_STAGE216_REGEN="${CJGUI_STAGE217_220_ALLOW_SLOW_STAGE216_REGEN:-false}" \
    zsh "$STAGE220_SUITE_SCRIPT" > "$STAGE220_LOG" 2>&1; then
    echo "cjgui stage221-224 render command refresh suite: stage217-220 suite failed" >&2
    echo "cjgui stage221-224 render command refresh suite: log=$STAGE220_LOG" >&2
    exit 8
  fi
  STAGE220_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE220_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage221-224 render command refresh suite: missing stage220 packet; set CJGUI_STAGE220_STATEFUL_INTERACTION_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE221_224_ALLOW_SLOW_STAGE220_REGEN=true" >&2
  exit 7
fi

stage220_packet="$STAGE220_SUITE_PACKET"
if [[ -z "$stage220_packet" || ! -f "$stage220_packet" ]]; then
  echo "cjgui stage221-224 render command refresh suite: missing stage220 packet" >&2
  exit 9
fi
for fact in \
  "stage217_220_state_update_after_action_runway_suite_passed=true" \
  "state_update_preview_packet_materialized=true" \
  "state_update_semantic_diff_materialized=true" \
  "state_update_explain_packet_materialized=true" \
  "state_update_rollback_ready_boundary_materialized=true" \
  "stateful_interaction_readiness_decision_materialized=true" \
  "stage221_render_command_refresh_after_state_update_preview_input_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage220_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage221-224 render command refresh suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage221-224 render command refresh suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage221-224 render command refresh suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage221-224 render command refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage221-224 render command refresh suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage221-224 render command refresh suite: runtime package build failed" >&2
  echo "cjgui stage221-224 render command refresh suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage220_route="$(fact_value "$stage220_packet" "next_route")"

{
  echo "stage221_224_render_command_refresh_after_state_update_suite_version=1"
  echo "stage220_stateful_interaction_readiness_decision_suite_packet=$stage220_packet"
  echo "stage220_next_route=$stage220_route"
  echo "build_log=$BUILD_LOG"
  echo "stage221_render_command_refresh_owner_passed=true"
  echo "stage222_refreshed_render_command_preview_packet_owner_passed=true"
  echo "stage223_render_command_refresh_semantic_diff_explain_owner_passed=true"
  echo "stage224_render_command_refresh_readiness_decision_owner_passed=true"
  echo "stage220_stateful_interaction_readiness_decision_consumed=true"
  echo "internal_render_command_packet_consumed=true"
  echo "state_update_preview_mapped_to_render_command_refresh=true"
  echo "button_like_semantic_node_bound_to_render_command_refresh=true"
  echo "render_command_refresh_preview_materialized=true"
  echo "owner_local_before_after_state_revisions_carried=true"
  echo "stage222_refreshed_render_command_preview_packet_input_prepared=true"
  echo "render_batching_packet_consumed=true"
  echo "refreshed_render_command_preview_packet_materialized=true"
  echo "refreshed_preview_packet_bound_to_state_update_preview=true"
  echo "refreshed_preview_packet_bound_to_state_update_semantic_diff=true"
  echo "refreshed_preview_packet_bound_to_rollback_boundary=true"
  echo "stage223_render_command_refresh_semantic_diff_input_prepared=true"
  echo "render_command_refresh_semantic_diff_materialized=true"
  echo "render_command_refresh_explain_packet_materialized=true"
  echo "render_command_refresh_rollback_ready_boundary_materialized=true"
  echo "stage224_render_command_refresh_readiness_decision_input_prepared=true"
  echo "state_update_preview_joined_with_refreshed_render_command_packet=true"
  echo "render_command_refresh_diff_explain_joined_with_rollback_boundary=true"
  echo "render_command_refresh_readiness_decision_materialized=true"
  echo "stage225_renderer_submission_preview_input_prepared=true"
  echo "minimal_ui_framework_render_command_refresh_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage221_224_public_foreign_scan_passed=true"
  echo "stage221_224_forbidden_native_render_token_scan_passed=true"
  echo "stage221_224_protected_path_scan_passed=true"
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
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_after_action=true"
  echo "state_update_committed=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage225_renderer_submission_preview_after_render_command_refresh"
  echo "stage221_224_render_command_refresh_after_state_update_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage221-224 render command refresh suite: route_classification=stage224_render_command_refresh_readiness_decision_ready"
echo "cjgui stage221-224 render command refresh suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage221-224 render command refresh suite: stage225_renderer_submission_preview_input_prepared=true"
echo "cjgui stage221-224 render command refresh suite: renderer_state_write=false"
