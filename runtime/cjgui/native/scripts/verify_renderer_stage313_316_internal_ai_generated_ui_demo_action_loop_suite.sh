#!/usr/bin/env zsh
#
# 维护注释：stage313-316 focused suite 串联 AI-generated UI demo action intent bridge、
# owner-local state update dry-run、refreshed RenderCommand preview 与 readiness decision。
# 输入是 stage312 suite packet；输出仍不 dispatch、不提交 state、不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE313_316_TMPDIR:-/tmp/cjgui-stage313-316-internal-ai-generated-ui-demo-action-loop-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage316-internal-ai-generated-ui-demo-action-loop-readiness-decision-suite.packet"
STAGE312_SUITE_PACKET="${CJGUI_STAGE312_INTERNAL_AI_GENERATED_UI_DEMO_PROBE_READINESS_DECISION_SUITE_PACKET:-}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage313_internal_ai_generated_ui_demo_action_intent_bridge_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage314_internal_ai_generated_ui_demo_action_state_update_dry_run_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage315_internal_ai_generated_ui_demo_refreshed_render_command_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage313_internal_ai_generated_ui_demo_action_intent_bridge.cj"
  "$ROOT_DIR/src/runtime_renderer_stage314_internal_ai_generated_ui_demo_action_state_update_dry_run.cj"
  "$ROOT_DIR/src/runtime_renderer_stage315_internal_ai_generated_ui_demo_refreshed_render_command_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision.cj"
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
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: owner probe failed $script" >&2
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "ai_generated_ui_action_intent_bridge_materialized=true"
require_file_fact "${owner_logs[2]}" "ai_generated_ui_action_state_update_dry_run_materialized=true"
require_file_fact "${owner_logs[3]}" "ai_generated_ui_action_refreshed_render_command_preview_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_ai_generated_ui_demo_action_loop_readiness_decision_materialized=true"

if [[ -z "$STAGE312_SUITE_PACKET" || ! -f "$STAGE312_SUITE_PACKET" ]]; then
  echo "cjgui stage313-316 internal ai generated ui demo action loop suite: missing stage312 packet; set CJGUI_STAGE312_INTERNAL_AI_GENERATED_UI_DEMO_PROBE_READINESS_DECISION_SUITE_PACKET" >&2
  exit 7
fi

for fact in \
  "stage309_312_internal_ai_generated_ui_demo_probe_suite_version=1" \
  "internal_ai_generated_ui_demo_probe_readiness_decision_materialized=true" \
  "stage313_internal_ai_generated_ui_demo_action_intent_bridge_prepared=true" \
  "minimal_ui_framework_ai_generated_ui_probe_runway_advanced=true" \
  "internal_ai_generated_ui_demo_probe_input_materialized=true" \
  "ai_generated_ui_probe_input_bound_to_generated_form_semantic_preview=true" \
  "ai_generated_ui_probe_input_bound_to_generated_settings_semantic_preview=true" \
  "ai_generated_ui_probe_input_bound_to_generated_validation_semantic_preview=true" \
  "ai_generated_ui_probe_input_bound_to_owner_local_state_delta=true" \
  "ai_generated_ui_probe_input_bound_to_render_command_preview=true" \
  "internal_ai_generated_ui_demo_probe_result_envelope_materialized=true" \
  "ai_generated_ui_probe_result_owner_local_in_memory_only=true" \
  "ai_generated_ui_probe_result_rollback_ready=true" \
  "ai_generated_ui_probe_result_visibility_not_published=true" \
  "ai_generated_ui_demo_probe_semantic_diff_materialized=true" \
  "ai_generated_ui_demo_probe_explain_packet_materialized=true" \
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
  require_file_fact "$STAGE312_SUITE_PACKET" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage313-316 internal ai generated ui demo action loop suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage313-316 internal ai generated ui demo action loop suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage313-316 internal ai generated ui demo action loop suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage313-316 internal ai generated ui demo action loop suite: runtime package build failed" >&2
  echo "cjgui stage313-316 internal ai generated ui demo action loop suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage312_route="$(fact_value "$STAGE312_SUITE_PACKET" "next_route")"

{
  echo "stage313_316_internal_ai_generated_ui_demo_action_loop_suite_version=1"
  echo "stage312_internal_ai_generated_ui_demo_probe_readiness_decision_suite_packet=$STAGE312_SUITE_PACKET"
  echo "stage312_next_route=$stage312_route"
  echo "build_log=$BUILD_LOG"
  echo "stage313_internal_ai_generated_ui_demo_action_intent_bridge_owner_passed=true"
  echo "stage314_internal_ai_generated_ui_demo_action_state_update_dry_run_owner_passed=true"
  echo "stage315_internal_ai_generated_ui_demo_refreshed_render_command_preview_owner_passed=true"
  echo "stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision_owner_passed=true"
  echo "stage312_internal_ai_generated_ui_demo_probe_readiness_decision_consumed=true"
  echo "ai_generated_ui_action_intent_bridge_materialized=true"
  echo "ai_generated_ui_action_intent_bound_to_probe_readiness=true"
  echo "ai_generated_ui_action_intent_bound_to_generated_form_intent=true"
  echo "ai_generated_ui_action_intent_bound_to_generated_settings_intent=true"
  echo "ai_generated_ui_action_intent_bound_to_generated_validation_intent=true"
  echo "ai_generated_ui_action_intent_bound_to_owner_acceptance_boundary=true"
  echo "ai_generated_ui_action_intent_owner_local_in_memory_only=true"
  echo "ai_generated_ui_action_intent_non_dispatching=true"
  echo "stage314_ai_generated_ui_action_state_update_dry_run_input_prepared=true"
  echo "ai_generated_ui_action_state_update_dry_run_materialized=true"
  echo "generated_form_action_state_update_dry_run_materialized=true"
  echo "generated_settings_action_state_update_dry_run_materialized=true"
  echo "generated_validation_action_state_update_dry_run_materialized=true"
  echo "ai_generated_ui_action_state_update_bound_to_owner_local_state_snapshot=true"
  echo "ai_generated_ui_action_state_update_bound_to_rollback_ready_boundary=true"
  echo "ai_generated_ui_action_state_update_owner_local_in_memory_only=true"
  echo "ai_generated_ui_action_state_update_uncommitted=true"
  echo "stage315_refreshed_render_command_preview_input_prepared=true"
  echo "ai_generated_ui_action_refreshed_render_command_preview_materialized=true"
  echo "refreshed_render_command_preview_bound_to_action_state_update_dry_run=true"
  echo "refreshed_render_command_preview_bound_to_generated_form_node=true"
  echo "refreshed_render_command_preview_bound_to_generated_settings_node=true"
  echo "refreshed_render_command_preview_bound_to_generated_validation_node=true"
  echo "refreshed_render_command_preview_bound_to_rollback_ready_boundary=true"
  echo "refreshed_render_command_preview_bound_to_visibility_not_published_boundary=true"
  echo "stage316_ai_generated_ui_action_loop_readiness_decision_input_prepared=true"
  echo "internal_ai_generated_ui_demo_action_loop_readiness_decision_materialized=true"
  echo "ai_generated_ui_action_intent_state_update_joined=true"
  echo "ai_generated_ui_action_state_update_refreshed_render_command_joined=true"
  echo "ai_generated_ui_action_loop_rollback_visibility_boundary_joined=true"
  echo "stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run_prepared=true"
  echo "minimal_ui_framework_ai_generated_ui_action_loop_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage313_316_public_foreign_scan_passed=true"
  echo "stage313_316_forbidden_native_render_token_scan_passed=true"
  echo "stage313_316_protected_path_scan_passed=true"
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
  echo "next_route=stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run_after_action_loop_readiness_decision"
  echo "stage313_316_internal_ai_generated_ui_demo_action_loop_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage313-316 internal ai generated ui demo action loop suite: route_classification=stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision_ready"
echo "cjgui stage313-316 internal ai generated ui demo action loop suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage313-316 internal ai generated ui demo action loop suite: stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run_prepared=true"
echo "cjgui stage313-316 internal ai generated ui demo action loop suite: renderer_state_write=false"
