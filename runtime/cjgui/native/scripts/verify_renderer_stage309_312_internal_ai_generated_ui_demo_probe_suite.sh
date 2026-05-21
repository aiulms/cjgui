#!/usr/bin/env zsh
#
# 维护注释：stage309-312 focused suite 串联 AI-generated UI demo probe input、
# result envelope、semantic diff/explain 与 readiness decision。输入是 stage308 suite packet。
# 输出仍不执行 action dispatch、不提交 state、不提交 renderer、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE309_312_TMPDIR:-/tmp/cjgui-stage309-312-internal-ai-generated-ui-demo-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage312-internal-ai-generated-ui-demo-probe-readiness-decision-suite.packet"
STAGE308_SUITE_PACKET="${CJGUI_STAGE308_INTERNAL_AI_GENERATED_UI_DEMO_COMPONENT_STATE_RENDER_READINESS_DECISION_SUITE_PACKET:-}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage309_internal_ai_generated_ui_demo_probe_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage310_internal_ai_generated_ui_demo_probe_result_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage311_internal_ai_generated_ui_demo_probe_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage312_internal_ai_generated_ui_demo_probe_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage309_internal_ai_generated_ui_demo_probe_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage310_internal_ai_generated_ui_demo_probe_result_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage311_internal_ai_generated_ui_demo_probe_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage312_internal_ai_generated_ui_demo_probe_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
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
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: owner probe failed $script" >&2
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "internal_ai_generated_ui_demo_probe_input_materialized=true"
require_file_fact "${owner_logs[2]}" "internal_ai_generated_ui_demo_probe_result_envelope_materialized=true"
require_file_fact "${owner_logs[3]}" "ai_generated_ui_demo_probe_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_ai_generated_ui_demo_probe_readiness_decision_materialized=true"

if [[ -z "$STAGE308_SUITE_PACKET" || ! -f "$STAGE308_SUITE_PACKET" ]]; then
  echo "cjgui stage309-312 internal ai generated ui demo probe suite: missing stage308 packet; set CJGUI_STAGE308_INTERNAL_AI_GENERATED_UI_DEMO_COMPONENT_STATE_RENDER_READINESS_DECISION_SUITE_PACKET" >&2
  exit 7
fi

for fact in \
  "stage305_308_internal_ai_generated_ui_demo_component_state_render_suite_version=1" \
  "internal_ai_generated_ui_component_state_render_readiness_decision_materialized=true" \
  "stage309_internal_ai_generated_ui_demo_probe_input_prepared=true" \
  "minimal_ui_framework_ai_generated_ui_component_state_render_runway_advanced=true" \
  "ai_generated_ui_component_state_render_dry_run_input_materialized=true" \
  "generated_form_proposal_bound_to_component_state_snapshot=true" \
  "generated_settings_proposal_bound_to_component_state_snapshot=true" \
  "component_state_render_dry_run_input_bound_to_render_command_refresh_requirement=true" \
  "generated_form_field_state_delta_dry_run_materialized=true" \
  "generated_settings_switch_state_delta_dry_run_materialized=true" \
  "generated_validation_state_delta_dry_run_materialized=true" \
  "generated_component_state_delta_bound_to_rollback_ready_boundary=true" \
  "generated_component_state_delta_in_memory_only=true" \
  "generated_form_semantic_node_preview_materialized=true" \
  "generated_settings_semantic_node_preview_materialized=true" \
  "generated_validation_message_semantic_node_preview_materialized=true" \
  "ai_generated_ui_component_render_command_preview_materialized=true" \
  "generated_component_render_preview_bound_to_state_delta_dry_run=true" \
  "generated_component_render_preview_bound_to_render_command_refresh_requirement=true" \
  "ai_generated_ui_component_state_render_dry_run_joined=true" \
  "ai_generated_ui_component_state_render_rollback_boundary_joined=true" \
  "ai_generated_ui_component_state_render_visibility_boundary_joined=true" \
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
  require_file_fact "$STAGE308_SUITE_PACKET" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage309-312 internal ai generated ui demo probe suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage309-312 internal ai generated ui demo probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage309-312 internal ai generated ui demo probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage309-312 internal ai generated ui demo probe suite: runtime package build failed" >&2
  echo "cjgui stage309-312 internal ai generated ui demo probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage308_route="$(fact_value "$STAGE308_SUITE_PACKET" "next_route")"

{
  echo "stage309_312_internal_ai_generated_ui_demo_probe_suite_version=1"
  echo "stage308_internal_ai_generated_ui_demo_component_state_render_readiness_decision_suite_packet=$STAGE308_SUITE_PACKET"
  echo "stage308_next_route=$stage308_route"
  echo "build_log=$BUILD_LOG"
  echo "stage309_internal_ai_generated_ui_demo_probe_input_owner_passed=true"
  echo "stage310_internal_ai_generated_ui_demo_probe_result_envelope_owner_passed=true"
  echo "stage311_internal_ai_generated_ui_demo_probe_semantic_diff_explain_owner_passed=true"
  echo "stage312_internal_ai_generated_ui_demo_probe_readiness_decision_owner_passed=true"
  echo "stage308_internal_ai_generated_ui_demo_component_state_render_readiness_decision_consumed=true"
  echo "internal_ai_generated_ui_demo_probe_input_materialized=true"
  echo "ai_generated_ui_probe_input_bound_to_generated_form_semantic_preview=true"
  echo "ai_generated_ui_probe_input_bound_to_generated_settings_semantic_preview=true"
  echo "ai_generated_ui_probe_input_bound_to_generated_validation_semantic_preview=true"
  echo "ai_generated_ui_probe_input_bound_to_owner_local_state_delta=true"
  echo "ai_generated_ui_probe_input_bound_to_render_command_preview=true"
  echo "ai_generated_ui_probe_input_bound_to_rollback_ready_boundary=true"
  echo "ai_generated_ui_probe_input_bound_to_visibility_not_published_boundary=true"
  echo "ai_generated_ui_probe_input_non_executing=true"
  echo "stage310_ai_generated_ui_demo_probe_result_envelope_input_prepared=true"
  echo "internal_ai_generated_ui_demo_probe_result_envelope_materialized=true"
  echo "ai_generated_ui_probe_result_envelope_bound_to_probe_input=true"
  echo "ai_generated_ui_probe_result_envelope_bound_to_component_state_delta_dry_run=true"
  echo "ai_generated_ui_probe_result_envelope_bound_to_render_command_preview=true"
  echo "ai_generated_ui_probe_result_owner_local_in_memory_only=true"
  echo "ai_generated_ui_probe_result_rollback_ready=true"
  echo "ai_generated_ui_probe_result_visibility_not_published=true"
  echo "stage311_ai_generated_ui_demo_probe_semantic_diff_explain_input_prepared=true"
  echo "ai_generated_ui_demo_probe_semantic_diff_materialized=true"
  echo "ai_generated_ui_demo_probe_explain_packet_materialized=true"
  echo "ai_generated_ui_probe_diff_bound_to_generated_form_settings_validation_order=true"
  echo "ai_generated_ui_probe_explain_bound_to_generated_proposal_state_render_loop=true"
  echo "ai_generated_ui_probe_rollback_ready_boundary_rechecked=true"
  echo "ai_generated_ui_probe_visibility_not_published_boundary_rechecked=true"
  echo "stage312_ai_generated_ui_demo_probe_readiness_decision_input_prepared=true"
  echo "internal_ai_generated_ui_demo_probe_readiness_decision_materialized=true"
  echo "ai_generated_ui_probe_input_result_diff_joined=true"
  echo "ai_generated_ui_probe_rollback_visibility_boundary_joined=true"
  echo "stage313_internal_ai_generated_ui_demo_action_intent_bridge_prepared=true"
  echo "minimal_ui_framework_ai_generated_ui_probe_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage309_312_public_foreign_scan_passed=true"
  echo "stage309_312_forbidden_native_render_token_scan_passed=true"
  echo "stage309_312_protected_path_scan_passed=true"
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
  echo "next_route=stage313_internal_ai_generated_ui_demo_action_intent_bridge_after_probe_readiness_decision"
  echo "stage309_312_internal_ai_generated_ui_demo_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage309-312 internal ai generated ui demo probe suite: route_classification=stage312_internal_ai_generated_ui_demo_probe_readiness_decision_ready"
echo "cjgui stage309-312 internal ai generated ui demo probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage309-312 internal ai generated ui demo probe suite: stage313_internal_ai_generated_ui_demo_action_intent_bridge_prepared=true"
echo "cjgui stage309-312 internal ai generated ui demo probe suite: renderer_state_write=false"
