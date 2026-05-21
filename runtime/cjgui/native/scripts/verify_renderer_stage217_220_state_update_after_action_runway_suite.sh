#!/usr/bin/env zsh
#
# 维护注释：stage217-220 focused suite 串联 action 后状态更新 dry-run、
# state preview packet、state diff/explain 与 stateful interaction readiness。
# 输入是 stage216 suite packet；输出仍不执行事件/动作，不提交状态，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE217_220_TMPDIR:-/tmp/cjgui-stage217-220-state-update-after-action-runway-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE216_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage213_216_interaction_runway_suite.sh"
STAGE216_LOG="$TMP_DIR/stage216.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage220-stateful-interaction-readiness-decision-suite.packet"
STAGE216_SUITE_PACKET="${CJGUI_STAGE216_INTERACTION_RUNWAY_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE216_REGEN="${CJGUI_STAGE217_220_ALLOW_SLOW_STAGE216_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage217_state_update_after_action_dry_run_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage218_state_update_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage219_state_update_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage220_stateful_interaction_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage217_state_update_after_action_dry_run.cj"
  "$ROOT_DIR/src/runtime_renderer_stage218_state_update_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage219_state_update_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage220_stateful_interaction_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE216_LOG"
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
    echo "cjgui stage217-220 state update after action suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE216_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage217-220 state update after action suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage217-220 state update after action suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage217-220 state update after action suite: owner probe failed $script" >&2
    echo "cjgui stage217-220 state update after action suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "state_update_after_action_dry_run_materialized=true"
require_file_fact "${owner_logs[2]}" "state_update_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "state_update_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "stateful_interaction_readiness_decision_materialized=true"

if [[ -n "$STAGE216_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE216_SUITE_PACKET" ]]; then
    echo "cjgui stage217-220 state update after action suite: provided stage216 packet missing $STAGE216_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage216_suite_packet_used=true"
    echo "stage216_suite_packet_path=$STAGE216_SUITE_PACKET"
  } > "$STAGE216_LOG"
elif [[ "$ALLOW_STAGE216_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE213_216_TMPDIR="$TMP_DIR/stage213-216" \
    CJGUI_STAGE213_216_ALLOW_SLOW_STAGE212_REGEN="${CJGUI_STAGE213_216_ALLOW_SLOW_STAGE212_REGEN:-false}" \
    zsh "$STAGE216_SUITE_SCRIPT" > "$STAGE216_LOG" 2>&1; then
    echo "cjgui stage217-220 state update after action suite: stage213-216 suite failed" >&2
    echo "cjgui stage217-220 state update after action suite: log=$STAGE216_LOG" >&2
    exit 8
  fi
  STAGE216_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE216_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage217-220 state update after action suite: missing stage216 packet; set CJGUI_STAGE216_INTERACTION_RUNWAY_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE217_220_ALLOW_SLOW_STAGE216_REGEN=true" >&2
  exit 7
fi

stage216_packet="$STAGE216_SUITE_PACKET"
if [[ -z "$stage216_packet" || ! -f "$stage216_packet" ]]; then
  echo "cjgui stage217-220 state update after action suite: missing stage216 packet" >&2
  exit 9
fi
for fact in \
  "stage213_216_interaction_runway_suite_passed=true" \
  "interaction_runway_readiness_decision_materialized=true" \
  "stage217_state_update_after_action_dry_run_input_prepared=true" \
  "action_preview_packet_materialized=true" \
  "action_rollback_ready_boundary_materialized=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage216_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage217-220 state update after action suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage217-220 state update after action suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage217-220 state update after action suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage217-220 state update after action suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage217-220 state update after action suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage217-220 state update after action suite: runtime package build failed" >&2
  echo "cjgui stage217-220 state update after action suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage216_route="$(fact_value "$stage216_packet" "next_route")"

{
  echo "stage217_220_state_update_after_action_runway_suite_version=1"
  echo "stage216_interaction_runway_readiness_decision_suite_packet=$stage216_packet"
  echo "stage216_next_route=$stage216_route"
  echo "build_log=$BUILD_LOG"
  echo "stage217_state_update_after_action_dry_run_owner_passed=true"
  echo "stage218_state_update_preview_packet_owner_passed=true"
  echo "stage219_state_update_semantic_diff_explain_owner_passed=true"
  echo "stage220_stateful_interaction_readiness_decision_owner_passed=true"
  echo "stage216_interaction_runway_readiness_decision_consumed=true"
  echo "action_intent_bound_to_owner_local_state_update_candidate=true"
  echo "state_update_after_action_dry_run_materialized=true"
  echo "state_update_rollback_preview_materialized=true"
  echo "stage218_state_update_preview_packet_input_prepared=true"
  echo "state_update_preview_packet_materialized=true"
  echo "state_update_preview_bound_to_action_preview=true"
  echo "state_update_preview_bound_to_rollback_preview=true"
  echo "state_update_preview_non_committing=true"
  echo "stage219_state_update_semantic_diff_input_prepared=true"
  echo "state_update_semantic_diff_materialized=true"
  echo "state_update_explain_packet_materialized=true"
  echo "state_update_rollback_ready_boundary_materialized=true"
  echo "stage220_stateful_interaction_readiness_decision_input_prepared=true"
  echo "action_preview_joined_with_state_update_preview_packet=true"
  echo "state_update_preview_joined_with_rollback_ready_boundary=true"
  echo "stateful_interaction_readiness_decision_materialized=true"
  echo "stage221_render_command_refresh_after_state_update_preview_input_prepared=true"
  echo "minimal_ui_framework_stateful_interaction_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage217_220_public_foreign_scan_passed=true"
  echo "stage217_220_forbidden_native_render_token_scan_passed=true"
  echo "stage217_220_protected_path_scan_passed=true"
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
  echo "next_route=stage221_render_command_refresh_after_state_update_preview"
  echo "stage217_220_state_update_after_action_runway_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage217-220 state update after action suite: route_classification=stage220_stateful_interaction_readiness_decision_ready"
echo "cjgui stage217-220 state update after action suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage217-220 state update after action suite: stage221_render_command_refresh_after_state_update_preview_input_prepared=true"
echo "cjgui stage217-220 state update after action suite: renderer_state_write=false"
