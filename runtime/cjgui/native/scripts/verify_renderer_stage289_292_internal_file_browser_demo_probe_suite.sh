#!/usr/bin/env zsh
#
# 维护注释：stage289-292 focused suite 串联 file browser probe input、result envelope、
# semantic diff/explain 与 readiness decision。输入是 stage288 suite packet。
# 输出仍不执行 action dispatch、不提交 state、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE289_292_TMPDIR:-/tmp/cjgui-stage289-292-internal-file-browser-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE288_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage285_288_internal_file_browser_demo_intent_state_render_suite.sh"
STAGE288_LOG="$TMP_DIR/stage288.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage292-internal-file-browser-demo-probe-readiness-decision-suite.packet"
STAGE288_SUITE_PACKET="${CJGUI_STAGE288_INTERNAL_FILE_BROWSER_DEMO_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE288_REGEN="${CJGUI_STAGE289_292_ALLOW_SLOW_STAGE288_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage289_internal_file_browser_demo_probe_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage290_internal_file_browser_demo_probe_result_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage291_internal_file_browser_demo_probe_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage292_internal_file_browser_demo_probe_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage289_internal_file_browser_demo_probe_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage290_internal_file_browser_demo_probe_result_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage291_internal_file_browser_demo_probe_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage292_internal_file_browser_demo_probe_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE288_LOG"
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
    echo "cjgui stage289-292 internal file browser demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE288_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage289-292 internal file browser demo probe suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage289-292 internal file browser demo probe suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage289-292 internal file browser demo probe suite: owner probe failed $script" >&2
    echo "cjgui stage289-292 internal file browser demo probe suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_file_browser_demo_probe_input_materialized=true"
require_file_fact "${owner_logs[2]}" "internal_file_browser_demo_probe_result_envelope_materialized=true"
require_file_fact "${owner_logs[3]}" "file_browser_demo_probe_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_file_browser_demo_probe_readiness_decision_materialized=true"

if [[ -n "$STAGE288_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE288_SUITE_PACKET" ]]; then
    echo "cjgui stage289-292 internal file browser demo probe suite: provided stage288 packet missing $STAGE288_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage288_suite_packet_used=true"
    echo "stage288_suite_packet_path=$STAGE288_SUITE_PACKET"
  } > "$STAGE288_LOG"
elif [[ "$ALLOW_STAGE288_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE285_288_TMPDIR="$TMP_DIR/stage285-288" \
    CJGUI_STAGE285_288_ALLOW_SLOW_STAGE284_REGEN=true \
    zsh "$STAGE288_SUITE_SCRIPT" > "$STAGE288_LOG" 2>&1; then
    echo "cjgui stage289-292 internal file browser demo probe suite: stage285-288 suite failed" >&2
    echo "cjgui stage289-292 internal file browser demo probe suite: log=$STAGE288_LOG" >&2
    exit 8
  fi
  STAGE288_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE288_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage289-292 internal file browser demo probe suite: missing stage288 packet; set CJGUI_STAGE288_INTERNAL_FILE_BROWSER_DEMO_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE289_292_ALLOW_SLOW_STAGE288_REGEN=true" >&2
  exit 7
fi

stage288_packet="$STAGE288_SUITE_PACKET"
if [[ -z "$stage288_packet" || ! -f "$stage288_packet" ]]; then
  echo "cjgui stage289-292 internal file browser demo probe suite: missing stage288 packet" >&2
  exit 9
fi
for fact in \
  "stage285_288_internal_file_browser_demo_intent_state_render_suite_passed=true" \
  "internal_file_browser_demo_readiness_decision_materialized=true" \
  "stage289_internal_file_browser_demo_probe_input_prepared=true" \
  "internal_file_browser_demo_intent_packet_materialized=true" \
  "file_browser_selection_intent_semantic_node_materialized=true" \
  "file_browser_tree_list_intent_semantic_node_materialized=true" \
  "file_browser_detail_pane_intent_semantic_node_materialized=true" \
  "file_browser_demo_owner_local_state_snapshot_materialized=true" \
  "file_browser_selection_state_delta_dry_run_materialized=true" \
  "file_browser_tree_expansion_state_delta_dry_run_materialized=true" \
  "file_browser_detail_pane_state_delta_dry_run_materialized=true" \
  "file_browser_shell_semantic_node_preview_materialized=true" \
  "file_browser_tree_row_semantic_node_preview_materialized=true" \
  "file_browser_list_selection_semantic_node_preview_materialized=true" \
  "file_browser_detail_pane_semantic_node_preview_materialized=true" \
  "file_browser_intent_state_render_joined=true" \
  "file_browser_rollback_visibility_boundary_joined=true" \
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
  require_file_fact "$stage288_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage289-292 internal file browser demo probe suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage289-292 internal file browser demo probe suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage289-292 internal file browser demo probe suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage289-292 internal file browser demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage289-292 internal file browser demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage289-292 internal file browser demo probe suite: runtime package build failed" >&2
  echo "cjgui stage289-292 internal file browser demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage288_route="$(fact_value "$stage288_packet" "next_route")"

{
  echo "stage289_292_internal_file_browser_demo_probe_suite_version=1"
  echo "stage288_internal_file_browser_demo_readiness_decision_suite_packet=$stage288_packet"
  echo "stage288_next_route=$stage288_route"
  echo "build_log=$BUILD_LOG"
  echo "stage289_internal_file_browser_demo_probe_input_owner_passed=true"
  echo "stage290_internal_file_browser_demo_probe_result_envelope_owner_passed=true"
  echo "stage291_internal_file_browser_demo_probe_semantic_diff_explain_owner_passed=true"
  echo "stage292_internal_file_browser_demo_probe_readiness_decision_owner_passed=true"
  echo "stage288_internal_file_browser_demo_readiness_decision_consumed=true"
  echo "internal_file_browser_demo_probe_input_materialized=true"
  echo "file_browser_probe_input_bound_to_selection_intent=true"
  echo "file_browser_probe_input_bound_to_tree_expansion_intent=true"
  echo "file_browser_probe_input_bound_to_detail_pane_refresh_intent=true"
  echo "file_browser_probe_input_bound_to_owner_local_state_delta=true"
  echo "file_browser_probe_input_bound_to_render_command_preview=true"
  echo "file_browser_probe_input_bound_to_rollback_ready_boundary=true"
  echo "file_browser_probe_input_bound_to_visibility_not_published_boundary=true"
  echo "file_browser_probe_input_non_executing=true"
  echo "stage290_file_browser_demo_probe_result_envelope_input_prepared=true"
  echo "internal_file_browser_demo_probe_result_envelope_materialized=true"
  echo "file_browser_probe_result_envelope_bound_to_probe_input=true"
  echo "file_browser_probe_result_envelope_bound_to_state_update_dry_run=true"
  echo "file_browser_probe_result_envelope_bound_to_render_command_preview=true"
  echo "file_browser_probe_result_owner_local_in_memory_only=true"
  echo "file_browser_probe_result_rollback_ready=true"
  echo "file_browser_probe_result_visibility_not_published=true"
  echo "stage291_file_browser_demo_probe_semantic_diff_explain_input_prepared=true"
  echo "file_browser_demo_probe_semantic_diff_materialized=true"
  echo "file_browser_demo_probe_explain_packet_materialized=true"
  echo "file_browser_probe_diff_bound_to_selection_tree_detail_order=true"
  echo "file_browser_probe_explain_bound_to_selection_tree_detail_intents=true"
  echo "file_browser_probe_rollback_ready_boundary_rechecked=true"
  echo "file_browser_probe_visibility_not_published_boundary_rechecked=true"
  echo "stage292_file_browser_demo_probe_readiness_decision_input_prepared=true"
  echo "internal_file_browser_demo_probe_readiness_decision_materialized=true"
  echo "file_browser_probe_input_result_diff_joined=true"
  echo "file_browser_probe_rollback_visibility_boundary_joined=true"
  echo "stage293_internal_ai_generated_ui_demo_semantic_spec_input_prepared=true"
  echo "minimal_ui_framework_file_browser_probe_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage289_292_public_foreign_scan_passed=true"
  echo "stage289_292_forbidden_native_render_token_scan_passed=true"
  echo "stage289_292_protected_path_scan_passed=true"
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
  echo "next_route=stage293_internal_ai_generated_ui_demo_semantic_spec_input_after_file_browser_probe_readiness_decision"
  echo "stage289_292_internal_file_browser_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage289-292 internal file browser demo probe suite: route_classification=stage292_internal_file_browser_demo_probe_readiness_decision_ready"
echo "cjgui stage289-292 internal file browser demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage289-292 internal file browser demo probe suite: stage293_internal_ai_generated_ui_demo_semantic_spec_input_prepared=true"
echo "cjgui stage289-292 internal file browser demo probe suite: renderer_state_write=false"
