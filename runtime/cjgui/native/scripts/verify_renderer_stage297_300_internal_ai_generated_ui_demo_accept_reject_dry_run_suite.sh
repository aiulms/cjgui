#!/usr/bin/env zsh
#
# 维护注释：stage297-300 focused suite 串联 AI-generated UI accept/reject
# dry-run input、result envelope、semantic diff/explain 与 readiness decision。
# 输入必须是 stage296 suite packet；本 suite 不递归重放历史阶段，避免慢链路空转。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE297_300_TMPDIR:-/tmp/cjgui-stage297-300-internal-ai-generated-ui-demo-accept-reject-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage300-internal-ai-generated-ui-demo-accept-reject-readiness-decision-suite.packet"
STAGE296_SUITE_PACKET="${CJGUI_STAGE296_INTERNAL_AI_GENERATED_UI_DEMO_READINESS_DECISION_SUITE_PACKET:-}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage298_internal_ai_generated_ui_demo_accept_reject_dry_run_result_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage299_internal_ai_generated_ui_demo_accept_reject_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage298_internal_ai_generated_ui_demo_accept_reject_dry_run_result_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage299_internal_ai_generated_ui_demo_accept_reject_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision.cj"
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
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: owner probe failed $script" >&2
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "ai_generated_ui_accept_reject_dry_run_input_materialized=true"
require_file_fact "${owner_logs[2]}" "ai_generated_ui_accept_reject_dry_run_result_envelope_materialized=true"
require_file_fact "${owner_logs[3]}" "ai_generated_ui_accept_reject_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_ai_generated_ui_accept_reject_readiness_decision_materialized=true"

if [[ -z "$STAGE296_SUITE_PACKET" || ! -f "$STAGE296_SUITE_PACKET" ]]; then
  echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: missing stage296 packet; set CJGUI_STAGE296_INTERNAL_AI_GENERATED_UI_DEMO_READINESS_DECISION_SUITE_PACKET" >&2
  exit 7
fi

for fact in \
  "stage293_296_internal_ai_generated_ui_demo_semantic_spec_suite_version=1" \
  "internal_ai_generated_ui_demo_readiness_decision_materialized=true" \
  "stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_prepared=true" \
  "minimal_ui_framework_ai_generated_ui_runway_advanced=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
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
  require_file_fact "$STAGE296_SUITE_PACKET" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: runtime package build failed" >&2
  echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage296_route="$(fact_value "$STAGE296_SUITE_PACKET" "next_route")"

{
  echo "stage297_300_internal_ai_generated_ui_demo_accept_reject_dry_run_suite_version=1"
  echo "stage296_internal_ai_generated_ui_demo_readiness_decision_suite_packet=$STAGE296_SUITE_PACKET"
  echo "stage296_next_route=$stage296_route"
  echo "build_log=$BUILD_LOG"
  echo "stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_owner_passed=true"
  echo "stage298_internal_ai_generated_ui_demo_accept_reject_dry_run_result_envelope_owner_passed=true"
  echo "stage299_internal_ai_generated_ui_demo_accept_reject_semantic_diff_explain_owner_passed=true"
  echo "stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision_owner_passed=true"
  echo "stage296_internal_ai_generated_ui_demo_readiness_decision_consumed=true"
  echo "ai_generated_ui_accept_reject_dry_run_input_materialized=true"
  echo "accept_dry_run_bound_to_owner_acceptance_requirement=true"
  echo "accept_dry_run_bound_to_generated_form_settings_preview=true"
  echo "reject_dry_run_bound_to_rollback_noop_path=true"
  echo "reject_dry_run_bound_to_explain_packet=true"
  echo "ai_generated_ui_accept_reject_input_owner_local_in_memory_only=true"
  echo "ai_generated_ui_accept_reject_input_non_executing=true"
  echo "stage298_ai_generated_ui_demo_accept_reject_dry_run_result_envelope_input_prepared=true"
  echo "ai_generated_ui_accept_reject_dry_run_result_envelope_materialized=true"
  echo "accept_result_bound_to_uncommitted_generated_ui_proposal=true"
  echo "reject_result_bound_to_rollback_ready_noop=true"
  echo "accept_reject_result_bound_to_visibility_not_published_boundary=true"
  echo "ai_generated_ui_accept_reject_result_owner_local_in_memory_only=true"
  echo "ai_generated_ui_accept_reject_result_rollback_ready=true"
  echo "stage299_ai_generated_ui_demo_accept_reject_semantic_diff_explain_input_prepared=true"
  echo "ai_generated_ui_accept_reject_semantic_diff_materialized=true"
  echo "ai_generated_ui_accept_reject_explain_packet_materialized=true"
  echo "accept_diff_bound_to_uncommitted_generated_ui_proposal=true"
  echo "reject_diff_bound_to_rollback_ready_noop=true"
  echo "ai_generated_ui_accept_reject_owner_acceptance_boundary_rechecked=true"
  echo "ai_generated_ui_accept_reject_visibility_not_published_boundary_rechecked=true"
  echo "stage300_ai_generated_ui_demo_accept_reject_readiness_decision_input_prepared=true"
  echo "internal_ai_generated_ui_accept_reject_readiness_decision_materialized=true"
  echo "ai_generated_ui_accept_reject_dry_run_input_result_diff_joined=true"
  echo "ai_generated_ui_accept_reject_owner_acceptance_boundary_joined=true"
  echo "ai_generated_ui_accept_reject_rollback_visibility_boundary_joined=true"
  echo "stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_input_prepared=true"
  echo "minimal_ui_framework_accept_reject_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage297_300_public_foreign_scan_passed=true"
  echo "stage297_300_forbidden_native_render_token_scan_passed=true"
  echo "stage297_300_protected_path_scan_passed=true"
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
  echo "next_route=stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_after_accept_reject_readiness_decision"
} > "$SUITE_PACKET"

echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: route_classification=stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision_ready"
echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_input_prepared=true"
echo "cjgui stage297-300 internal ai generated ui demo accept reject dry run suite: renderer_state_write=false"
