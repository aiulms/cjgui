#!/usr/bin/env zsh
#
# 维护注释：stage209-212 focused suite 串联 layout/style first-slice、
# styled preview packet、semantic diff/explain 与 UI framework runway decision。
# 输入是 stage208 suite packet；输出仍不发布 visibility、不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE209_212_TMPDIR:-/tmp/cjgui-stage209-212-layout-style-runway-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE208_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage205_208_component_demo_render_command_preview_suite.sh"
STAGE208_LOG="$TMP_DIR/stage208.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage212-ui-framework-runway-readiness-decision-suite.packet"
STAGE208_SUITE_PACKET="${CJGUI_STAGE208_COMPONENT_DEMO_UI_RUNWAY_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE208_REGEN="${CJGUI_STAGE209_212_ALLOW_SLOW_STAGE208_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage209_layout_style_first_slice_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage210_styled_component_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage211_layout_style_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage212_ui_framework_runway_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage209_layout_style_first_slice.cj"
  "$ROOT_DIR/src/runtime_renderer_stage210_styled_component_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage211_layout_style_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage212_ui_framework_runway_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE208_LOG"
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
    echo "cjgui stage209-212 layout/style runway suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE208_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage209-212 layout/style runway suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage209-212 layout/style runway suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage209-212 layout/style runway suite: owner probe failed $script" >&2
    echo "cjgui stage209-212 layout/style runway suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "rect_layout_value_facts_materialized=true"
require_file_fact "${owner_logs[2]}" "styled_component_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "layout_style_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "ui_framework_runway_readiness_decision_materialized=true"

if [[ -n "$STAGE208_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE208_SUITE_PACKET" ]]; then
    echo "cjgui stage209-212 layout/style runway suite: provided stage208 packet missing $STAGE208_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage208_suite_packet_used=true"
    echo "stage208_suite_packet_path=$STAGE208_SUITE_PACKET"
  } > "$STAGE208_LOG"
elif [[ "$ALLOW_STAGE208_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE205_208_TMPDIR="$TMP_DIR/stage205-208" \
    CJGUI_STAGE205_208_ALLOW_SLOW_STAGE204_REGEN="${CJGUI_STAGE205_208_ALLOW_SLOW_STAGE204_REGEN:-true}" \
    zsh "$STAGE208_SUITE_SCRIPT" > "$STAGE208_LOG" 2>&1; then
    echo "cjgui stage209-212 layout/style runway suite: stage205-208 suite failed" >&2
    echo "cjgui stage209-212 layout/style runway suite: log=$STAGE208_LOG" >&2
    exit 8
  fi
  STAGE208_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE208_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage209-212 layout/style runway suite: missing stage208 packet; set CJGUI_STAGE208_COMPONENT_DEMO_UI_RUNWAY_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE209_212_ALLOW_SLOW_STAGE208_REGEN=true" >&2
  exit 7
fi

stage208_packet="$STAGE208_SUITE_PACKET"
if [[ -z "$stage208_packet" || ! -f "$stage208_packet" ]]; then
  echo "cjgui stage209-212 layout/style runway suite: missing stage208 packet" >&2
  exit 9
fi
for fact in \
  "stage205_208_component_demo_render_command_preview_suite_passed=true" \
  "component_demo_preview_packet_materialized=true" \
  "semantic_preview_diff_materialized=true" \
  "semantic_explain_packet_materialized=true" \
  "rollback_ready_preview_boundary_materialized=true" \
  "ui_runway_readiness_decision_materialized=true" \
  "stage209_layout_style_first_slice_input_prepared=true" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage208_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage209-212 layout/style runway suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage209-212 layout/style runway suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage209-212 layout/style runway suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage209-212 layout/style runway suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage209-212 layout/style runway suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage209-212 layout/style runway suite: runtime package build failed" >&2
  echo "cjgui stage209-212 layout/style runway suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage208_route="$(fact_value "$stage208_packet" "next_route")"

{
  echo "stage209_212_layout_style_runway_suite_version=1"
  echo "stage208_component_demo_ui_runway_readiness_decision_suite_packet=$stage208_packet"
  echo "stage208_next_route=$stage208_route"
  echo "build_log=$BUILD_LOG"
  echo "stage209_layout_style_first_slice_owner_passed=true"
  echo "stage210_styled_component_preview_packet_owner_passed=true"
  echo "stage211_layout_style_semantic_diff_explain_owner_passed=true"
  echo "stage212_ui_framework_runway_readiness_decision_owner_passed=true"
  echo "stage208_ui_runway_readiness_decision_consumed=true"
  echo "component_demo_preview_packet_consumed=true"
  echo "rect_layout_value_facts_materialized=true"
  echo "text_typography_value_facts_materialized=true"
  echo "button_style_value_facts_materialized=true"
  echo "style_token_value_facts_materialized=true"
  echo "stage210_styled_component_preview_packet_input_prepared=true"
  echo "layout_style_facts_joined_with_preview_packet=true"
  echo "styled_component_preview_packet_materialized=true"
  echo "rect_layout_bound_to_render_command_admission_preview=true"
  echo "text_typography_bound_to_semantic_explain_packet=true"
  echo "button_style_bound_to_owner_local_rollback_boundary=true"
  echo "stage211_layout_style_semantic_diff_input_prepared=true"
  echo "layout_style_semantic_diff_materialized=true"
  echo "layout_style_explain_packet_materialized=true"
  echo "style_rollback_ready_boundary_materialized=true"
  echo "owner_acceptance_required=true"
  echo "stage212_ui_framework_runway_readiness_decision_input_prepared=true"
  echo "layout_style_facts_joined_with_styled_preview_packet=true"
  echo "ui_framework_runway_readiness_decision_materialized=true"
  echo "stage213_input_action_first_slice_input_prepared=true"
  echo "minimal_ui_framework_runway_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage209_212_public_foreign_scan_passed=true"
  echo "stage209_212_forbidden_native_render_token_scan_passed=true"
  echo "stage209_212_protected_path_scan_passed=true"
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
  echo "next_route=stage213_input_action_first_slice_after_layout_style_runway_readiness_decision"
  echo "stage209_212_layout_style_runway_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage209-212 layout/style runway suite: route_classification=stage212_ui_framework_runway_readiness_ready"
echo "cjgui stage209-212 layout/style runway suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage209-212 layout/style runway suite: stage213_input_action_first_slice_input_prepared=true"
echo "cjgui stage209-212 layout/style runway suite: renderer_state_write=false"
