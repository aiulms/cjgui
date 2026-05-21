#!/usr/bin/env zsh
#
# 维护注释：stage205-208 focused suite 串联 component demo RenderCommand
# admission、preview packet、semantic diff/explain 与 UI runway readiness decision。
# 输入是 stage204 suite packet；输出不发布 visibility、不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE205_208_TMPDIR:-/tmp/cjgui-stage205-208-component-demo-render-command-preview-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE204_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage201_204_ui_runway_suite.sh"
STAGE204_LOG="$TMP_DIR/stage204.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage208-component-demo-ui-runway-readiness-decision-suite.packet"
STAGE204_SUITE_PACKET="${CJGUI_STAGE204_COMPONENT_DEMO_STATE_UPDATE_DRY_RUN_SUITE_PACKET:-}"
ALLOW_STAGE204_REGEN="${CJGUI_STAGE205_208_ALLOW_SLOW_STAGE204_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage205_component_demo_render_command_admission_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage206_component_demo_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage207_semantic_preview_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage208_component_demo_ui_runway_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage205_component_demo_render_command_admission.cj"
  "$ROOT_DIR/src/runtime_renderer_stage206_component_demo_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage207_semantic_preview_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage208_component_demo_ui_runway_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE204_LOG"
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
    echo "cjgui stage205-208 component demo preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE204_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage205-208 component demo preview suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage205-208 component demo preview suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage205-208 component demo preview suite: owner probe failed $script" >&2
    echo "cjgui stage205-208 component demo preview suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "render_command_admission_preview_materialized=true"
require_file_fact "${owner_logs[2]}" "component_demo_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "semantic_preview_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "ui_runway_readiness_decision_materialized=true"

if [[ -n "$STAGE204_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE204_SUITE_PACKET" ]]; then
    echo "cjgui stage205-208 component demo preview suite: provided stage204 packet missing $STAGE204_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage204_suite_packet_used=true"
    echo "stage204_suite_packet_path=$STAGE204_SUITE_PACKET"
  } > "$STAGE204_LOG"
elif [[ "$ALLOW_STAGE204_REGEN" == "true" ]]; then
  if ! env CJGUI_STAGE201_204_TMPDIR="$TMP_DIR/stage201-204" zsh "$STAGE204_SUITE_SCRIPT" > "$STAGE204_LOG" 2>&1; then
    echo "cjgui stage205-208 component demo preview suite: stage201-204 suite failed" >&2
    echo "cjgui stage205-208 component demo preview suite: log=$STAGE204_LOG" >&2
    exit 8
  fi
  STAGE204_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE204_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage205-208 component demo preview suite: missing stage204 packet; set CJGUI_STAGE204_COMPONENT_DEMO_STATE_UPDATE_DRY_RUN_SUITE_PACKET or CJGUI_STAGE205_208_ALLOW_SLOW_STAGE204_REGEN=true" >&2
  exit 7
fi

stage204_packet="$STAGE204_SUITE_PACKET"
if [[ -z "$stage204_packet" || ! -f "$stage204_packet" ]]; then
  echo "cjgui stage205-208 component demo preview suite: missing stage204 packet" >&2
  exit 9
fi
for fact in \
  "stage201_204_ui_runway_suite_passed=true" \
  "component_demo_state_update_dry_run_materialized=true" \
  "owner_local_rollback_preview_materialized=true" \
  "visibility_not_published_boundary_materialized=true" \
  "stage205_component_demo_render_command_admission_input_prepared=true" \
  "minimal_ui_framework_runway_input_prepared=true" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage204_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage205-208 component demo preview suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage205-208 component demo preview suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage205-208 component demo preview suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage205-208 component demo preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage205-208 component demo preview suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage205-208 component demo preview suite: runtime package build failed" >&2
  echo "cjgui stage205-208 component demo preview suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage204_route="$(fact_value "$stage204_packet" "next_route")"

{
  echo "stage205_208_component_demo_render_command_preview_suite_version=1"
  echo "stage204_component_demo_state_update_dry_run_suite_packet=$stage204_packet"
  echo "stage204_next_route=$stage204_route"
  echo "build_log=$BUILD_LOG"
  echo "stage205_component_demo_render_command_admission_owner_passed=true"
  echo "stage206_component_demo_preview_packet_owner_passed=true"
  echo "stage207_semantic_preview_diff_explain_owner_passed=true"
  echo "stage208_component_demo_ui_runway_readiness_decision_owner_passed=true"
  echo "stage204_component_demo_state_update_dry_run_consumed=true"
  echo "internal_render_command_packet_consumed=true"
  echo "component_demo_semantic_fixture_mapped_to_render_command_packet=true"
  echo "render_command_admission_preview_materialized=true"
  echo "stage206_component_demo_preview_packet_input_prepared=true"
  echo "render_batching_packet_consumed=true"
  echo "component_demo_preview_packet_materialized=true"
  echo "owner_local_rollback_boundary_bound=true"
  echo "preview_visibility_not_published=true"
  echo "stage207_semantic_preview_diff_input_prepared=true"
  echo "semantic_preview_diff_materialized=true"
  echo "semantic_explain_packet_materialized=true"
  echo "rollback_ready_preview_boundary_materialized=true"
  echo "owner_acceptance_required=true"
  echo "stage208_ui_runway_readiness_decision_input_prepared=true"
  echo "render_command_admission_preview_joined=true"
  echo "component_demo_preview_packet_joined=true"
  echo "ui_runway_readiness_decision_materialized=true"
  echo "stage209_layout_style_first_slice_input_prepared=true"
  echo "minimal_ui_framework_runway_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage205_208_public_foreign_scan_passed=true"
  echo "stage205_208_forbidden_native_render_token_scan_passed=true"
  echo "stage205_208_protected_path_scan_passed=true"
  echo "renderer_state_write_token=false"
  echo "renderer_state_write_eligibility=false"
  echo "result_envelope_promotion_token=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "owner_acceptance_granted=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage209_layout_style_first_slice_after_component_demo_ui_runway_readiness_decision"
  echo "stage205_208_component_demo_render_command_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage205-208 component demo preview suite: route_classification=stage208_ui_runway_readiness_decision_ready"
echo "cjgui stage205-208 component demo preview suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage205-208 component demo preview suite: stage209_layout_style_first_slice_input_prepared=true"
echo "cjgui stage205-208 component demo preview suite: renderer_state_write=false"
