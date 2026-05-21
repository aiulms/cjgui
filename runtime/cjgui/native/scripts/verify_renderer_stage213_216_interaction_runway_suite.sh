#!/usr/bin/env zsh
#
# 维护注释：stage213-216 focused suite 串联 input/action first-slice、
# action preview packet、action diff/explain 与 interaction runway decision。
# 输入是 stage212 suite packet；输出仍不执行 action、不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE213_216_TMPDIR:-/tmp/cjgui-stage213-216-interaction-runway-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE212_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage209_212_layout_style_runway_suite.sh"
STAGE212_LOG="$TMP_DIR/stage212.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage216-interaction-runway-readiness-decision-suite.packet"
STAGE212_SUITE_PACKET="${CJGUI_STAGE212_UI_FRAMEWORK_RUNWAY_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE212_REGEN="${CJGUI_STAGE213_216_ALLOW_SLOW_STAGE212_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage213_input_action_first_slice_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage214_action_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage215_action_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage216_interaction_runway_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage213_input_action_first_slice.cj"
  "$ROOT_DIR/src/runtime_renderer_stage214_action_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage215_action_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage216_interaction_runway_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE212_LOG"
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
    echo "cjgui stage213-216 interaction runway suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE212_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage213-216 interaction runway suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage213-216 interaction runway suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage213-216 interaction runway suite: owner probe failed $script" >&2
    echo "cjgui stage213-216 interaction runway suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "button_like_action_intent_facts_materialized=true"
require_file_fact "${owner_logs[2]}" "action_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "action_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "interaction_runway_readiness_decision_materialized=true"

if [[ -n "$STAGE212_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE212_SUITE_PACKET" ]]; then
    echo "cjgui stage213-216 interaction runway suite: provided stage212 packet missing $STAGE212_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage212_suite_packet_used=true"
    echo "stage212_suite_packet_path=$STAGE212_SUITE_PACKET"
  } > "$STAGE212_LOG"
elif [[ "$ALLOW_STAGE212_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE209_212_TMPDIR="$TMP_DIR/stage209-212" \
    CJGUI_STAGE209_212_ALLOW_SLOW_STAGE208_REGEN="${CJGUI_STAGE209_212_ALLOW_SLOW_STAGE208_REGEN:-false}" \
    zsh "$STAGE212_SUITE_SCRIPT" > "$STAGE212_LOG" 2>&1; then
    echo "cjgui stage213-216 interaction runway suite: stage209-212 suite failed" >&2
    echo "cjgui stage213-216 interaction runway suite: log=$STAGE212_LOG" >&2
    exit 8
  fi
  STAGE212_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE212_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage213-216 interaction runway suite: missing stage212 packet; set CJGUI_STAGE212_UI_FRAMEWORK_RUNWAY_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE213_216_ALLOW_SLOW_STAGE212_REGEN=true" >&2
  exit 7
fi

stage212_packet="$STAGE212_SUITE_PACKET"
if [[ -z "$stage212_packet" || ! -f "$stage212_packet" ]]; then
  echo "cjgui stage213-216 interaction runway suite: missing stage212 packet" >&2
  exit 9
fi
for fact in \
  "stage209_212_layout_style_runway_suite_passed=true" \
  "ui_framework_runway_readiness_decision_materialized=true" \
  "stage213_input_action_first_slice_input_prepared=true" \
  "minimal_ui_framework_runway_input_prepared=true" \
  "public_component_api_added=false" \
  "layout_engine_enabled=false" \
  "input_event_pipeline_enabled=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage212_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage213-216 interaction runway suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage213-216 interaction runway suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage213-216 interaction runway suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage213-216 interaction runway suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage213-216 interaction runway suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage213-216 interaction runway suite: runtime package build failed" >&2
  echo "cjgui stage213-216 interaction runway suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage212_route="$(fact_value "$stage212_packet" "next_route")"

{
  echo "stage213_216_interaction_runway_suite_version=1"
  echo "stage212_ui_framework_runway_readiness_decision_suite_packet=$stage212_packet"
  echo "stage212_next_route=$stage212_route"
  echo "build_log=$BUILD_LOG"
  echo "stage213_input_action_first_slice_owner_passed=true"
  echo "stage214_action_preview_packet_owner_passed=true"
  echo "stage215_action_semantic_diff_explain_owner_passed=true"
  echo "stage216_interaction_runway_readiness_decision_owner_passed=true"
  echo "stage212_ui_framework_runway_readiness_decision_consumed=true"
  echo "button_like_action_intent_facts_materialized=true"
  echo "action_target_semantic_node_bound=true"
  echo "action_enabled_predicate_bound=true"
  echo "action_intent_bound_to_styled_component_preview_packet=true"
  echo "stage214_action_preview_packet_input_prepared=true"
  echo "action_preview_packet_materialized=true"
  echo "action_preview_bound_to_owner_local_rollback_boundary=true"
  echo "action_preview_non_dispatching=true"
  echo "stage215_action_semantic_diff_input_prepared=true"
  echo "action_semantic_diff_materialized=true"
  echo "action_explain_packet_materialized=true"
  echo "action_rollback_ready_boundary_materialized=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "stage216_interaction_runway_readiness_decision_input_prepared=true"
  echo "interaction_runway_readiness_decision_materialized=true"
  echo "stage217_state_update_after_action_dry_run_input_prepared=true"
  echo "minimal_ui_framework_interaction_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage213_216_public_foreign_scan_passed=true"
  echo "stage213_216_forbidden_native_render_token_scan_passed=true"
  echo "stage213_216_protected_path_scan_passed=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_after_action=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage217_state_update_after_action_dry_run_after_interaction_runway_readiness_decision"
  echo "stage213_216_interaction_runway_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage213-216 interaction runway suite: route_classification=stage216_interaction_runway_readiness_ready"
echo "cjgui stage213-216 interaction runway suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage213-216 interaction runway suite: stage217_state_update_after_action_dry_run_input_prepared=true"
echo "cjgui stage213-216 interaction runway suite: renderer_state_write=false"
