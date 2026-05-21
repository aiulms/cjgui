#!/usr/bin/env zsh
#
# 维护注释：stage321-324 focused suite 串联 AI-generated UI demo backend result
# preview、semantic diff/explain、state/render bridge 与 readiness decision。
# 输入是 stage320 suite packet；输出继续保持 no-submit / owner-local / no-write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE321_324_TMPDIR:-/tmp/cjgui-stage321-324-internal-ai-generated-ui-demo-backend-result-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage324-internal-ai-generated-ui-demo-backend-result-readiness-decision-suite.packet"
STAGE320_SUITE_PACKET="${CJGUI_STAGE320_INTERNAL_AI_GENERATED_UI_DEMO_BACKEND_ADAPTER_READINESS_DECISION_SUITE_PACKET:-}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage321_internal_ai_generated_ui_demo_backend_result_preview_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage322_internal_ai_generated_ui_demo_backend_result_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage323_internal_ai_generated_ui_demo_backend_result_state_render_bridge_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage321_internal_ai_generated_ui_demo_backend_result_preview.cj"
  "$ROOT_DIR/src/runtime_renderer_stage322_internal_ai_generated_ui_demo_backend_result_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage323_internal_ai_generated_ui_demo_backend_result_state_render_bridge.cj"
  "$ROOT_DIR/src/runtime_renderer_stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision.cj"
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
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: owner probe failed $script" >&2
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "ai_generated_ui_backend_result_preview_materialized=true"
require_file_fact "${owner_logs[2]}" "ai_generated_ui_backend_result_semantic_diff_materialized=true"
require_file_fact "${owner_logs[3]}" "ai_generated_ui_backend_result_state_render_bridge_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_ai_generated_ui_demo_backend_result_readiness_decision_materialized=true"

if [[ -z "$STAGE320_SUITE_PACKET" || ! -f "$STAGE320_SUITE_PACKET" ]]; then
  echo "cjgui stage321-324 internal ai generated ui demo backend result suite: missing stage320 packet; set CJGUI_STAGE320_INTERNAL_AI_GENERATED_UI_DEMO_BACKEND_ADAPTER_READINESS_DECISION_SUITE_PACKET" >&2
  exit 7
fi

for fact in \
  "stage317_320_internal_ai_generated_ui_demo_backend_adapter_suite_version=1" \
  "internal_ai_generated_ui_demo_backend_adapter_readiness_decision_materialized=true" \
  "stage321_internal_ai_generated_ui_demo_backend_result_preview_prepared=true" \
  "ai_generated_ui_action_loop_backend_adapter_dry_run_materialized=true" \
  "ai_generated_ui_backend_adapter_dry_run_result_envelope_materialized=true" \
  "ai_generated_ui_backend_adapter_semantic_diff_materialized=true" \
  "backend_adapter_result_owner_local_in_memory_only=true" \
  "backend_adapter_result_visibility_not_published=true" \
  "backend_adapter_runway_rollback_visibility_boundary_joined=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "platform_command_buffer=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE320_SUITE_PACKET" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage321-324 internal ai generated ui demo backend result suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage321-324 internal ai generated ui demo backend result suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage321-324 internal ai generated ui demo backend result suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage321-324 internal ai generated ui demo backend result suite: runtime package build failed" >&2
  echo "cjgui stage321-324 internal ai generated ui demo backend result suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage320_route="$(fact_value "$STAGE320_SUITE_PACKET" "next_route")"

{
  echo "stage321_324_internal_ai_generated_ui_demo_backend_result_suite_version=1"
  echo "stage320_internal_ai_generated_ui_demo_backend_adapter_readiness_decision_suite_packet=$STAGE320_SUITE_PACKET"
  echo "stage320_next_route=$stage320_route"
  echo "build_log=$BUILD_LOG"
  echo "stage321_internal_ai_generated_ui_demo_backend_result_preview_owner_passed=true"
  echo "stage322_internal_ai_generated_ui_demo_backend_result_semantic_diff_explain_owner_passed=true"
  echo "stage323_internal_ai_generated_ui_demo_backend_result_state_render_bridge_owner_passed=true"
  echo "stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_owner_passed=true"
  echo "stage320_internal_ai_generated_ui_demo_backend_adapter_readiness_decision_consumed=true"
  echo "ai_generated_ui_backend_result_preview_materialized=true"
  echo "backend_result_preview_bound_to_backend_adapter_result_envelope=true"
  echo "backend_result_preview_bound_to_backend_adapter_semantic_diff_explain=true"
  echo "backend_result_preview_bound_to_action_loop_refreshed_render_command=true"
  echo "backend_result_preview_owner_local_in_memory_only=true"
  echo "backend_adapter_rollback_visibility_boundary_preserved=true"
  echo "stage322_backend_result_semantic_diff_explain_input_prepared=true"
  echo "ai_generated_ui_backend_result_semantic_diff_materialized=true"
  echo "ai_generated_ui_backend_result_explain_packet_materialized=true"
  echo "backend_result_diff_bound_to_backend_result_preview=true"
  echo "backend_result_explain_bound_to_adapter_no_submit_result=true"
  echo "backend_result_rollback_ready_boundary_materialized=true"
  echo "stage323_backend_result_state_render_bridge_input_prepared=true"
  echo "ai_generated_ui_backend_result_state_render_bridge_materialized=true"
  echo "backend_result_bound_to_owner_local_state_update_dry_run=true"
  echo "backend_result_bound_to_refreshed_render_command_preview=true"
  echo "backend_result_state_commit_rejected=true"
  echo "backend_result_renderer_submission_rejected=true"
  echo "backend_result_visibility_publication_rejected=true"
  echo "stage324_backend_result_readiness_decision_input_prepared=true"
  echo "internal_ai_generated_ui_demo_backend_result_readiness_decision_materialized=true"
  echo "backend_result_preview_semantic_diff_explain_joined=true"
  echo "backend_result_bridge_state_render_dry_run_joined=true"
  echo "backend_result_runway_rollback_visibility_boundary_joined=true"
  echo "stage325_internal_ai_generated_ui_demo_result_to_surface_prepared=true"
  echo "minimal_ui_framework_ai_generated_ui_backend_result_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage321_324_public_foreign_scan_passed=true"
  echo "stage321_324_forbidden_native_render_token_scan_passed=true"
  echo "stage321_324_protected_path_scan_passed=true"
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
  echo "next_route=stage325_internal_ai_generated_ui_demo_result_to_surface_after_backend_result_readiness_decision"
  echo "stage321_324_internal_ai_generated_ui_demo_backend_result_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage321-324 internal ai generated ui demo backend result suite: route_classification=stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_ready"
echo "cjgui stage321-324 internal ai generated ui demo backend result suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage321-324 internal ai generated ui demo backend result suite: stage325_internal_ai_generated_ui_demo_result_to_surface_prepared=true"
echo "cjgui stage321-324 internal ai generated ui demo backend result suite: renderer_state_write=false"
