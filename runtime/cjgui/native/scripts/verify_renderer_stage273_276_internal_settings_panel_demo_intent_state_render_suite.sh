#!/usr/bin/env zsh
#
# 维护注释：stage273-276 focused suite 串联 settings panel intent、state dry-run、
# render preview 与 readiness decision。输入是 stage272 suite packet。
# 输出仍不执行 action dispatch、不提交 state、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE273_276_TMPDIR:-/tmp/cjgui-stage273-276-internal-settings-panel-demo-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE272_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage269_272_internal_todo_demo_probe_suite.sh"
STAGE272_LOG="$TMP_DIR/stage272.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage276-internal-settings-panel-demo-readiness-decision-suite.packet"
STAGE272_SUITE_PACKET="${CJGUI_STAGE272_INTERNAL_TODO_DEMO_PROBE_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE272_REGEN="${CJGUI_STAGE273_276_ALLOW_SLOW_STAGE272_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage273_internal_settings_panel_demo_intent_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage274_internal_settings_panel_demo_state_update_dry_run_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage275_internal_settings_panel_demo_render_command_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage276_internal_settings_panel_demo_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage273_internal_settings_panel_demo_intent_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage274_internal_settings_panel_demo_state_update_dry_run.cj"
  "$ROOT_DIR/src/runtime_renderer_stage275_internal_settings_panel_demo_render_command_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage276_internal_settings_panel_demo_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE272_LOG"
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
    echo "cjgui stage273-276 internal settings panel demo suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE272_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage273-276 internal settings panel demo suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage273-276 internal settings panel demo suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage273-276 internal settings panel demo suite: owner probe failed $script" >&2
    echo "cjgui stage273-276 internal settings panel demo suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_settings_panel_demo_intent_packet_materialized=true"
require_file_fact "${owner_logs[2]}" "settings_panel_demo_owner_local_state_snapshot_materialized=true"
require_file_fact "${owner_logs[3]}" "settings_panel_semantic_node_preview_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_settings_panel_demo_readiness_decision_materialized=true"

if [[ -n "$STAGE272_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE272_SUITE_PACKET" ]]; then
    echo "cjgui stage273-276 internal settings panel demo suite: provided stage272 packet missing $STAGE272_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage272_suite_packet_used=true"
    echo "stage272_suite_packet_path=$STAGE272_SUITE_PACKET"
  } > "$STAGE272_LOG"
elif [[ "$ALLOW_STAGE272_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE269_272_TMPDIR="$TMP_DIR/stage269-272" \
    CJGUI_STAGE269_272_ALLOW_SLOW_STAGE268_REGEN=true \
    zsh "$STAGE272_SUITE_SCRIPT" > "$STAGE272_LOG" 2>&1; then
    echo "cjgui stage273-276 internal settings panel demo suite: stage269-272 suite failed" >&2
    echo "cjgui stage273-276 internal settings panel demo suite: log=$STAGE272_LOG" >&2
    exit 8
  fi
  STAGE272_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE272_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage273-276 internal settings panel demo suite: missing stage272 packet; set CJGUI_STAGE272_INTERNAL_TODO_DEMO_PROBE_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE273_276_ALLOW_SLOW_STAGE272_REGEN=true" >&2
  exit 7
fi

stage272_packet="$STAGE272_SUITE_PACKET"
if [[ -z "$stage272_packet" || ! -f "$stage272_packet" ]]; then
  echo "cjgui stage273-276 internal settings panel demo suite: missing stage272 packet" >&2
  exit 9
fi
for fact in \
  "stage269_272_internal_todo_demo_probe_suite_passed=true" \
  "internal_todo_demo_probe_readiness_decision_materialized=true" \
  "stage273_internal_settings_panel_demo_intent_packet_input_prepared=true" \
  "internal_todo_demo_probe_input_materialized=true" \
  "internal_todo_demo_probe_result_envelope_materialized=true" \
  "todo_demo_probe_semantic_diff_materialized=true" \
  "todo_probe_input_result_diff_joined=true" \
  "todo_probe_rollback_visibility_boundary_joined=true" \
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
  require_file_fact "$stage272_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage273-276 internal settings panel demo suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage273-276 internal settings panel demo suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage273-276 internal settings panel demo suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage273-276 internal settings panel demo suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage273-276 internal settings panel demo suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage273-276 internal settings panel demo suite: runtime package build failed" >&2
  echo "cjgui stage273-276 internal settings panel demo suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage272_route="$(fact_value "$stage272_packet" "next_route")"

{
  echo "stage273_276_internal_settings_panel_demo_intent_state_render_suite_version=1"
  echo "stage272_internal_todo_demo_probe_readiness_decision_suite_packet=$stage272_packet"
  echo "stage272_next_route=$stage272_route"
  echo "build_log=$BUILD_LOG"
  echo "stage273_internal_settings_panel_demo_intent_packet_owner_passed=true"
  echo "stage274_internal_settings_panel_demo_state_update_dry_run_owner_passed=true"
  echo "stage275_internal_settings_panel_demo_render_command_preview_owner_passed=true"
  echo "stage276_internal_settings_panel_demo_readiness_decision_owner_passed=true"
  echo "stage272_internal_todo_demo_probe_readiness_decision_consumed=true"
  echo "internal_settings_panel_demo_intent_packet_materialized=true"
  echo "settings_switch_intent_semantic_node_materialized=true"
  echo "settings_group_intent_semantic_node_materialized=true"
  echo "settings_form_row_intent_semantic_node_materialized=true"
  echo "settings_intent_packet_bound_to_owner_local_state_delta_input=true"
  echo "settings_intent_packet_bound_to_render_command_refresh_requirement=true"
  echo "stage274_settings_panel_demo_state_update_dry_run_input_prepared=true"
  echo "settings_panel_demo_owner_local_state_snapshot_materialized=true"
  echo "settings_switch_toggle_state_delta_dry_run_materialized=true"
  echo "settings_group_expansion_state_delta_dry_run_materialized=true"
  echo "settings_form_row_edit_state_delta_dry_run_materialized=true"
  echo "settings_state_delta_bound_to_rollback_ready_boundary=true"
  echo "settings_state_update_dry_run_in_memory_only=true"
  echo "stage275_settings_panel_demo_render_command_preview_input_prepared=true"
  echo "settings_panel_semantic_node_preview_materialized=true"
  echo "settings_section_group_semantic_node_preview_materialized=true"
  echo "settings_switch_semantic_node_preview_materialized=true"
  echo "settings_form_row_semantic_node_preview_materialized=true"
  echo "settings_render_preview_bound_to_state_delta_dry_run=true"
  echo "settings_render_preview_bound_to_render_command_refresh_requirement=true"
  echo "stage276_settings_panel_demo_readiness_decision_input_prepared=true"
  echo "internal_settings_panel_demo_readiness_decision_materialized=true"
  echo "settings_panel_intent_state_render_joined=true"
  echo "settings_panel_rollback_visibility_boundary_joined=true"
  echo "stage277_internal_chat_view_demo_intent_packet_input_prepared=true"
  echo "minimal_ui_framework_settings_panel_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage273_276_public_foreign_scan_passed=true"
  echo "stage273_276_forbidden_native_render_token_scan_passed=true"
  echo "stage273_276_protected_path_scan_passed=true"
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
  echo "next_route=stage277_internal_chat_view_demo_intent_packet_after_settings_panel_readiness_decision"
  echo "stage273_276_internal_settings_panel_demo_intent_state_render_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage273-276 internal settings panel demo suite: route_classification=stage276_internal_settings_panel_demo_readiness_decision_ready"
echo "cjgui stage273-276 internal settings panel demo suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage273-276 internal settings panel demo suite: stage277_internal_chat_view_demo_intent_packet_input_prepared=true"
echo "cjgui stage273-276 internal settings panel demo suite: renderer_state_write=false"
