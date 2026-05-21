#!/usr/bin/env zsh
#
# 维护注释：stage293-296 focused suite 串联 AI-generated UI semantic spec input、
# preview packet、semantic diff/explain 与 readiness decision。输入是 stage292 suite packet。
# 输出只准备 accept/reject dry-run 入口，不接纳 owner 变更、不提交 state 或 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE293_296_TMPDIR:-/tmp/cjgui-stage293-296-internal-ai-generated-ui-demo-semantic-spec-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE292_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage289_292_internal_file_browser_demo_probe_suite.sh"
STAGE292_LOG="$TMP_DIR/stage292.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage296-internal-ai-generated-ui-demo-readiness-decision-suite.packet"
STAGE292_SUITE_PACKET="${CJGUI_STAGE292_INTERNAL_FILE_BROWSER_DEMO_PROBE_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE292_REGEN="${CJGUI_STAGE293_296_ALLOW_SLOW_STAGE292_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage293_internal_ai_generated_ui_demo_semantic_spec_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage294_internal_ai_generated_ui_demo_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage295_internal_ai_generated_ui_demo_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage296_internal_ai_generated_ui_demo_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage293_internal_ai_generated_ui_demo_semantic_spec_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage294_internal_ai_generated_ui_demo_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage295_internal_ai_generated_ui_demo_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage296_internal_ai_generated_ui_demo_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE292_LOG"
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
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE292_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: owner probe failed $script" >&2
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_ai_generated_ui_demo_semantic_spec_input_materialized=true"
require_file_fact "${owner_logs[2]}" "ai_generated_ui_demo_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "ai_generated_ui_demo_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_ai_generated_ui_demo_readiness_decision_materialized=true"

if [[ -n "$STAGE292_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE292_SUITE_PACKET" ]]; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: provided stage292 packet missing $STAGE292_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage292_suite_packet_used=true"
    echo "stage292_suite_packet_path=$STAGE292_SUITE_PACKET"
  } > "$STAGE292_LOG"
elif [[ "$ALLOW_STAGE292_REGEN" == "true" ]]; then
  # 防止 slow regen 递归重放所有历史 stage；这里只允许从显式 stage288 packet 重建 stage292。
  if [[ -z "${CJGUI_STAGE288_INTERNAL_FILE_BROWSER_DEMO_READINESS_DECISION_SUITE_PACKET:-}" ]]; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: slow stage292 regen requires CJGUI_STAGE288_INTERNAL_FILE_BROWSER_DEMO_READINESS_DECISION_SUITE_PACKET; recursive historical regen is disabled" >&2
    exit 8
  fi
  if ! env \
    CJGUI_STAGE289_292_TMPDIR="$TMP_DIR/stage289-292" \
    CJGUI_STAGE288_INTERNAL_FILE_BROWSER_DEMO_READINESS_DECISION_SUITE_PACKET="$CJGUI_STAGE288_INTERNAL_FILE_BROWSER_DEMO_READINESS_DECISION_SUITE_PACKET" \
    zsh "$STAGE292_SUITE_SCRIPT" > "$STAGE292_LOG" 2>&1; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: stage289-292 suite failed" >&2
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: log=$STAGE292_LOG" >&2
    exit 8
  fi
  STAGE292_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE292_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: missing stage292 packet; set CJGUI_STAGE292_INTERNAL_FILE_BROWSER_DEMO_PROBE_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE293_296_ALLOW_SLOW_STAGE292_REGEN=true" >&2
  exit 7
fi

stage292_packet="$STAGE292_SUITE_PACKET"
if [[ -z "$stage292_packet" || ! -f "$stage292_packet" ]]; then
  echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: missing stage292 packet" >&2
  exit 9
fi
for fact in \
  "stage289_292_internal_file_browser_demo_probe_suite_passed=true" \
  "internal_file_browser_demo_probe_readiness_decision_materialized=true" \
  "stage293_internal_ai_generated_ui_demo_semantic_spec_input_prepared=true" \
  "internal_file_browser_demo_probe_input_materialized=true" \
  "file_browser_probe_input_bound_to_selection_intent=true" \
  "file_browser_probe_input_bound_to_tree_expansion_intent=true" \
  "file_browser_probe_input_bound_to_detail_pane_refresh_intent=true" \
  "file_browser_probe_result_owner_local_in_memory_only=true" \
  "file_browser_probe_result_rollback_ready=true" \
  "file_browser_probe_result_visibility_not_published=true" \
  "file_browser_demo_probe_semantic_diff_materialized=true" \
  "file_browser_demo_probe_explain_packet_materialized=true" \
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
  require_file_fact "$stage292_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: runtime package build failed" >&2
  echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage292_route="$(fact_value "$stage292_packet" "next_route")"

{
  echo "stage293_296_internal_ai_generated_ui_demo_semantic_spec_suite_version=1"
  echo "stage292_internal_file_browser_demo_probe_readiness_decision_suite_packet=$stage292_packet"
  echo "stage292_next_route=$stage292_route"
  echo "build_log=$BUILD_LOG"
  echo "stage293_internal_ai_generated_ui_demo_semantic_spec_input_owner_passed=true"
  echo "stage294_internal_ai_generated_ui_demo_preview_packet_owner_passed=true"
  echo "stage295_internal_ai_generated_ui_demo_semantic_diff_explain_owner_passed=true"
  echo "stage296_internal_ai_generated_ui_demo_readiness_decision_owner_passed=true"
  echo "stage292_internal_file_browser_demo_probe_readiness_decision_consumed=true"
  echo "internal_ai_generated_ui_demo_semantic_spec_input_materialized=true"
  echo "ai_generated_ui_semantic_spec_bound_to_generated_form_intent=true"
  echo "ai_generated_ui_semantic_spec_bound_to_generated_settings_intent=true"
  echo "ai_generated_ui_semantic_spec_bound_to_preview_diff_explain_input=true"
  echo "ai_generated_ui_semantic_spec_bound_to_owner_acceptance_boundary=true"
  echo "ai_generated_ui_semantic_spec_owner_local_in_memory_only=true"
  echo "ai_generated_ui_semantic_spec_non_executing=true"
  echo "stage294_ai_generated_ui_demo_preview_packet_input_prepared=true"
  echo "ai_generated_ui_demo_preview_packet_materialized=true"
  echo "ai_generated_ui_preview_bound_to_semantic_spec_input=true"
  echo "ai_generated_ui_preview_bound_to_generated_form_semantic_node=true"
  echo "ai_generated_ui_preview_bound_to_generated_settings_semantic_node=true"
  echo "ai_generated_ui_preview_bound_to_render_command_requirement=true"
  echo "ai_generated_ui_preview_bound_to_owner_acceptance_boundary=true"
  echo "ai_generated_ui_preview_owner_local_in_memory_only=true"
  echo "ai_generated_ui_preview_non_executing=true"
  echo "stage295_ai_generated_ui_demo_semantic_diff_explain_input_prepared=true"
  echo "ai_generated_ui_demo_semantic_diff_materialized=true"
  echo "ai_generated_ui_demo_explain_packet_materialized=true"
  echo "ai_generated_ui_diff_bound_to_spec_preview_order=true"
  echo "ai_generated_ui_explain_bound_to_generated_form_settings_intents=true"
  echo "ai_generated_ui_owner_acceptance_boundary_rechecked=true"
  echo "ai_generated_ui_visibility_not_published_boundary_rechecked=true"
  echo "stage296_ai_generated_ui_demo_readiness_decision_input_prepared=true"
  echo "internal_ai_generated_ui_demo_readiness_decision_materialized=true"
  echo "ai_generated_ui_spec_preview_diff_joined=true"
  echo "ai_generated_ui_owner_acceptance_boundary_joined=true"
  echo "ai_generated_ui_visibility_not_published_boundary_joined=true"
  echo "stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_prepared=true"
  echo "minimal_ui_framework_ai_generated_ui_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage293_296_public_foreign_scan_passed=true"
  echo "stage293_296_forbidden_native_render_token_scan_passed=true"
  echo "stage293_296_protected_path_scan_passed=true"
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
  echo "next_route=stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_after_semantic_spec_readiness_decision"
  echo "stage293_296_internal_ai_generated_ui_demo_semantic_spec_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: route_classification=stage296_internal_ai_generated_ui_demo_readiness_decision_ready"
echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_prepared=true"
echo "cjgui stage293-296 internal ai generated ui demo semantic spec suite: renderer_state_write=false"
