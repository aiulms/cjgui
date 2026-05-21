#!/usr/bin/env zsh
#
# 维护注释：stage325-328 focused suite 串联 AI-generated UI demo result-to-surface、
# result-to-probe input、result envelope 与 readiness decision。
# 输入是 stage324 suite packet；输出继续保持 owner-local / non-executing / no-write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE325_328_TMPDIR:-/tmp/cjgui-stage325-328-internal-ai-generated-ui-demo-result-to-surface-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage328-internal-ai-generated-ui-demo-result-to-probe-readiness-decision-suite.packet"
STAGE324_SUITE_PACKET="${CJGUI_STAGE324_INTERNAL_AI_GENERATED_UI_DEMO_BACKEND_RESULT_READINESS_DECISION_SUITE_PACKET:-}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage325_internal_ai_generated_ui_demo_result_to_surface_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage326_internal_ai_generated_ui_demo_result_to_probe_input_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage327_internal_ai_generated_ui_demo_result_to_probe_result_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage325_internal_ai_generated_ui_demo_result_to_surface.cj"
  "$ROOT_DIR/src/runtime_renderer_stage326_internal_ai_generated_ui_demo_result_to_probe_input.cj"
  "$ROOT_DIR/src/runtime_renderer_stage327_internal_ai_generated_ui_demo_result_to_probe_result_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision.cj"
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
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: owner probe failed $script" >&2
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "ai_generated_ui_demo_result_to_surface_materialized=true"
require_file_fact "${owner_logs[2]}" "ai_generated_ui_demo_result_to_probe_input_materialized=true"
require_file_fact "${owner_logs[3]}" "ai_generated_ui_demo_result_to_probe_result_envelope_materialized=true"
require_file_fact "${owner_logs[4]}" "internal_ai_generated_ui_demo_result_to_probe_readiness_decision_materialized=true"

if [[ -z "$STAGE324_SUITE_PACKET" || ! -f "$STAGE324_SUITE_PACKET" ]]; then
  echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: missing stage324 packet; set CJGUI_STAGE324_INTERNAL_AI_GENERATED_UI_DEMO_BACKEND_RESULT_READINESS_DECISION_SUITE_PACKET" >&2
  exit 7
fi

for fact in \
  "stage321_324_internal_ai_generated_ui_demo_backend_result_suite_version=1" \
  "internal_ai_generated_ui_demo_backend_result_readiness_decision_materialized=true" \
  "stage325_internal_ai_generated_ui_demo_result_to_surface_prepared=true" \
  "ai_generated_ui_backend_result_preview_materialized=true" \
  "ai_generated_ui_backend_result_state_render_bridge_materialized=true" \
  "backend_result_bound_to_owner_local_state_update_dry_run=true" \
  "backend_result_bound_to_refreshed_render_command_preview=true" \
  "backend_result_runway_rollback_visibility_boundary_joined=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "visibility_published=false" \
  "state_update_committed=false" \
  "public_component_api_added=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE324_SUITE_PACKET" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: runtime package build failed" >&2
  echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage324_route="$(fact_value "$STAGE324_SUITE_PACKET" "next_route")"

{
  echo "stage325_328_internal_ai_generated_ui_demo_result_to_surface_probe_suite_version=1"
  echo "stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_suite_packet=$STAGE324_SUITE_PACKET"
  echo "stage324_next_route=$stage324_route"
  echo "build_log=$BUILD_LOG"
  echo "stage325_internal_ai_generated_ui_demo_result_to_surface_owner_passed=true"
  echo "stage326_internal_ai_generated_ui_demo_result_to_probe_input_owner_passed=true"
  echo "stage327_internal_ai_generated_ui_demo_result_to_probe_result_envelope_owner_passed=true"
  echo "stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision_owner_passed=true"
  echo "stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_consumed=true"
  echo "ai_generated_ui_demo_result_to_surface_materialized=true"
  echo "result_to_surface_bound_to_backend_result_preview=true"
  echo "result_to_surface_bound_to_state_render_bridge=true"
  echo "result_to_surface_bound_to_refreshed_render_command_preview=true"
  echo "result_to_surface_owner_local_in_memory_only=true"
  echo "result_to_surface_visibility_not_published=true"
  echo "stage326_internal_ai_generated_ui_demo_result_to_probe_input_prepared=true"
  echo "ai_generated_ui_demo_result_to_probe_input_materialized=true"
  echo "result_to_probe_input_bound_to_surface_refresh=true"
  echo "result_to_probe_input_bound_to_backend_result_readiness=true"
  echo "result_to_probe_input_bound_to_owner_local_state_render_bridge=true"
  echo "result_to_probe_input_owner_local_in_memory_only=true"
  echo "result_to_probe_input_non_executing=true"
  echo "stage327_internal_ai_generated_ui_demo_result_to_probe_result_envelope_prepared=true"
  echo "ai_generated_ui_demo_result_to_probe_result_envelope_materialized=true"
  echo "result_to_probe_envelope_bound_to_non_executing_input=true"
  echo "result_to_probe_envelope_bound_to_surface_refresh=true"
  echo "result_to_probe_envelope_owner_local_in_memory_only=true"
  echo "result_to_probe_envelope_rollback_ready=true"
  echo "result_to_probe_envelope_visibility_not_published=true"
  echo "stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision_input_prepared=true"
  echo "internal_ai_generated_ui_demo_result_to_probe_readiness_decision_materialized=true"
  echo "result_to_surface_probe_input_joined=true"
  echo "result_to_probe_input_envelope_joined=true"
  echo "result_to_probe_runway_rollback_visibility_boundary_joined=true"
  echo "stage329_internal_ai_generated_ui_demo_execution_dry_run_prepared=true"
  echo "minimal_ui_framework_ai_generated_ui_result_to_probe_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage325_328_public_foreign_scan_passed=true"
  echo "stage325_328_forbidden_native_render_token_scan_passed=true"
  echo "stage325_328_protected_path_scan_passed=true"
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
  echo "next_route=stage329_internal_ai_generated_ui_demo_execution_dry_run_after_result_to_probe_readiness_decision"
  echo "stage325_328_internal_ai_generated_ui_demo_result_to_surface_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: route_classification=stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision_ready"
echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: stage329_internal_ai_generated_ui_demo_execution_dry_run_prepared=true"
echo "cjgui stage325-328 internal ai generated ui demo result to surface probe suite: renderer_state_write=false"
