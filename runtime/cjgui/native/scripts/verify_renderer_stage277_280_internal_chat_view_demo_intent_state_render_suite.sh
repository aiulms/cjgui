#!/usr/bin/env zsh
#
# 维护注释：stage277-280 focused suite 串联 chat view intent、state dry-run、
# render preview 与 readiness decision。输入是 stage276 suite packet。
# 输出仍不执行 action dispatch、不提交 state、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE277_280_TMPDIR:-/tmp/cjgui-stage277-280-internal-chat-view-demo-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE276_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage273_276_internal_settings_panel_demo_intent_state_render_suite.sh"
STAGE276_LOG="$TMP_DIR/stage276.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage280-internal-chat-view-demo-readiness-decision-suite.packet"
STAGE276_SUITE_PACKET="${CJGUI_STAGE276_INTERNAL_SETTINGS_PANEL_DEMO_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE276_REGEN="${CJGUI_STAGE277_280_ALLOW_SLOW_STAGE276_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage277_internal_chat_view_demo_intent_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage278_internal_chat_view_demo_state_update_dry_run_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage279_internal_chat_view_demo_render_command_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage280_internal_chat_view_demo_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage277_internal_chat_view_demo_intent_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage278_internal_chat_view_demo_state_update_dry_run.cj"
  "$ROOT_DIR/src/runtime_renderer_stage279_internal_chat_view_demo_render_command_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage280_internal_chat_view_demo_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE276_LOG"
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
    echo "cjgui stage277-280 internal chat view demo suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE276_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage277-280 internal chat view demo suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage277-280 internal chat view demo suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage277-280 internal chat view demo suite: owner probe failed $script" >&2
    echo "cjgui stage277-280 internal chat view demo suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_chat_view_demo_intent_packet_materialized=true"
require_file_fact "${owner_logs[2]}" "chat_view_demo_owner_local_state_snapshot_materialized=true"
require_file_fact "${owner_logs[3]}" "chat_conversation_semantic_node_preview_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_chat_view_demo_readiness_decision_materialized=true"

if [[ -n "$STAGE276_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE276_SUITE_PACKET" ]]; then
    echo "cjgui stage277-280 internal chat view demo suite: provided stage276 packet missing $STAGE276_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage276_suite_packet_used=true"
    echo "stage276_suite_packet_path=$STAGE276_SUITE_PACKET"
  } > "$STAGE276_LOG"
elif [[ "$ALLOW_STAGE276_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE273_276_TMPDIR="$TMP_DIR/stage273-276" \
    CJGUI_STAGE273_276_ALLOW_SLOW_STAGE272_REGEN=true \
    zsh "$STAGE276_SUITE_SCRIPT" > "$STAGE276_LOG" 2>&1; then
    echo "cjgui stage277-280 internal chat view demo suite: stage273-276 suite failed" >&2
    echo "cjgui stage277-280 internal chat view demo suite: log=$STAGE276_LOG" >&2
    exit 8
  fi
  STAGE276_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE276_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage277-280 internal chat view demo suite: missing stage276 packet; set CJGUI_STAGE276_INTERNAL_SETTINGS_PANEL_DEMO_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE277_280_ALLOW_SLOW_STAGE276_REGEN=true" >&2
  exit 7
fi

stage276_packet="$STAGE276_SUITE_PACKET"
if [[ -z "$stage276_packet" || ! -f "$stage276_packet" ]]; then
  echo "cjgui stage277-280 internal chat view demo suite: missing stage276 packet" >&2
  exit 9
fi
for fact in \
  "stage273_276_internal_settings_panel_demo_intent_state_render_suite_passed=true" \
  "internal_settings_panel_demo_readiness_decision_materialized=true" \
  "stage277_internal_chat_view_demo_intent_packet_input_prepared=true" \
  "internal_settings_panel_demo_intent_packet_materialized=true" \
  "settings_panel_demo_owner_local_state_snapshot_materialized=true" \
  "settings_panel_semantic_node_preview_materialized=true" \
  "settings_panel_intent_state_render_joined=true" \
  "settings_panel_rollback_visibility_boundary_joined=true" \
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
  require_file_fact "$stage276_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage277-280 internal chat view demo suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage277-280 internal chat view demo suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage277-280 internal chat view demo suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage277-280 internal chat view demo suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage277-280 internal chat view demo suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage277-280 internal chat view demo suite: runtime package build failed" >&2
  echo "cjgui stage277-280 internal chat view demo suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage276_route="$(fact_value "$stage276_packet" "next_route")"

{
  echo "stage277_280_internal_chat_view_demo_intent_state_render_suite_version=1"
  echo "stage276_internal_settings_panel_demo_readiness_decision_suite_packet=$stage276_packet"
  echo "stage276_next_route=$stage276_route"
  echo "build_log=$BUILD_LOG"
  echo "stage277_internal_chat_view_demo_intent_packet_owner_passed=true"
  echo "stage278_internal_chat_view_demo_state_update_dry_run_owner_passed=true"
  echo "stage279_internal_chat_view_demo_render_command_preview_owner_passed=true"
  echo "stage280_internal_chat_view_demo_readiness_decision_owner_passed=true"
  echo "stage276_internal_settings_panel_demo_readiness_decision_consumed=true"
  echo "internal_chat_view_demo_intent_packet_materialized=true"
  echo "chat_message_list_intent_semantic_node_materialized=true"
  echo "chat_composer_intent_semantic_node_materialized=true"
  echo "chat_send_intent_semantic_node_materialized=true"
  echo "chat_intent_packet_bound_to_owner_local_state_delta_input=true"
  echo "chat_intent_packet_bound_to_render_command_refresh_requirement=true"
  echo "stage278_chat_view_demo_state_update_dry_run_input_prepared=true"
  echo "chat_view_demo_owner_local_state_snapshot_materialized=true"
  echo "chat_message_append_state_delta_dry_run_materialized=true"
  echo "chat_composer_clear_state_delta_dry_run_materialized=true"
  echo "chat_pending_delivery_state_delta_dry_run_materialized=true"
  echo "chat_state_delta_bound_to_rollback_ready_boundary=true"
  echo "chat_state_update_dry_run_in_memory_only=true"
  echo "stage279_chat_view_demo_render_command_preview_input_prepared=true"
  echo "chat_conversation_semantic_node_preview_materialized=true"
  echo "chat_message_bubble_semantic_node_preview_materialized=true"
  echo "chat_composer_semantic_node_preview_materialized=true"
  echo "chat_send_button_semantic_node_preview_materialized=true"
  echo "chat_render_preview_bound_to_state_delta_dry_run=true"
  echo "chat_render_preview_bound_to_render_command_refresh_requirement=true"
  echo "stage280_chat_view_demo_readiness_decision_input_prepared=true"
  echo "internal_chat_view_demo_readiness_decision_materialized=true"
  echo "chat_view_intent_state_render_joined=true"
  echo "chat_view_rollback_visibility_boundary_joined=true"
  echo "stage281_internal_chat_view_demo_probe_input_prepared=true"
  echo "minimal_ui_framework_chat_view_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage277_280_public_foreign_scan_passed=true"
  echo "stage277_280_forbidden_native_render_token_scan_passed=true"
  echo "stage277_280_protected_path_scan_passed=true"
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
  echo "next_route=stage281_internal_chat_view_demo_probe_input_after_chat_view_readiness_decision"
  echo "stage277_280_internal_chat_view_demo_intent_state_render_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage277-280 internal chat view demo suite: route_classification=stage280_internal_chat_view_demo_readiness_decision_ready"
echo "cjgui stage277-280 internal chat view demo suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage277-280 internal chat view demo suite: stage281_internal_chat_view_demo_probe_input_prepared=true"
echo "cjgui stage277-280 internal chat view demo suite: renderer_state_write=false"
