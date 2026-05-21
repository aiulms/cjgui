#!/usr/bin/env zsh
#
# 维护注释：stage225-228 focused suite 串联 renderer submission preview、
# preview packet、semantic diff/explain 与 readiness decision。
# 输入是 stage224 suite packet；输出仍不提交 renderer、不写 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE225_228_TMPDIR:-/tmp/cjgui-stage225-228-renderer-submission-preview-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE224_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage221_224_render_command_refresh_after_state_update_suite.sh"
STAGE224_LOG="$TMP_DIR/stage224.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage228-renderer-submission-readiness-decision-suite.packet"
STAGE224_SUITE_PACKET="${CJGUI_STAGE224_RENDER_COMMAND_REFRESH_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE224_REGEN="${CJGUI_STAGE225_228_ALLOW_SLOW_STAGE224_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage225_renderer_submission_preview_after_render_command_refresh_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage226_renderer_submission_preview_packet_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage227_renderer_submission_semantic_diff_explain_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage228_renderer_submission_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage225_renderer_submission_preview_after_render_command_refresh.cj"
  "$ROOT_DIR/src/runtime_renderer_stage226_renderer_submission_preview_packet.cj"
  "$ROOT_DIR/src/runtime_renderer_stage227_renderer_submission_semantic_diff_explain.cj"
  "$ROOT_DIR/src/runtime_renderer_stage228_renderer_submission_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE224_LOG"
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
    echo "cjgui stage225-228 renderer submission preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE224_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage225-228 renderer submission preview suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage225-228 renderer submission preview suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage225-228 renderer submission preview suite: owner probe failed $script" >&2
    echo "cjgui stage225-228 renderer submission preview suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "renderer_submission_preview_materialized=true"
require_file_fact "${owner_logs[2]}" "renderer_submission_preview_packet_materialized=true"
require_file_fact "${owner_logs[3]}" "renderer_submission_semantic_diff_materialized=true"
require_file_fact "${owner_logs[4]}" "renderer_submission_readiness_decision_materialized=true"

if [[ -n "$STAGE224_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE224_SUITE_PACKET" ]]; then
    echo "cjgui stage225-228 renderer submission preview suite: provided stage224 packet missing $STAGE224_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage224_suite_packet_used=true"
    echo "stage224_suite_packet_path=$STAGE224_SUITE_PACKET"
  } > "$STAGE224_LOG"
elif [[ "$ALLOW_STAGE224_REGEN" == "true" ]]; then
  if ! env \
    CJGUI_STAGE221_224_TMPDIR="$TMP_DIR/stage221-224" \
    CJGUI_STAGE221_224_ALLOW_SLOW_STAGE220_REGEN="${CJGUI_STAGE221_224_ALLOW_SLOW_STAGE220_REGEN:-false}" \
    zsh "$STAGE224_SUITE_SCRIPT" > "$STAGE224_LOG" 2>&1; then
    echo "cjgui stage225-228 renderer submission preview suite: stage221-224 suite failed" >&2
    echo "cjgui stage225-228 renderer submission preview suite: log=$STAGE224_LOG" >&2
    exit 8
  fi
  STAGE224_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE224_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage225-228 renderer submission preview suite: missing stage224 packet; set CJGUI_STAGE224_RENDER_COMMAND_REFRESH_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE225_228_ALLOW_SLOW_STAGE224_REGEN=true" >&2
  exit 7
fi

stage224_packet="$STAGE224_SUITE_PACKET"
if [[ -z "$stage224_packet" || ! -f "$stage224_packet" ]]; then
  echo "cjgui stage225-228 renderer submission preview suite: missing stage224 packet" >&2
  exit 9
fi
for fact in \
  "stage221_224_render_command_refresh_after_state_update_suite_passed=true" \
  "render_command_refresh_preview_materialized=true" \
  "refreshed_render_command_preview_packet_materialized=true" \
  "render_command_refresh_semantic_diff_materialized=true" \
  "render_command_refresh_explain_packet_materialized=true" \
  "render_command_refresh_rollback_ready_boundary_materialized=true" \
  "render_command_refresh_readiness_decision_materialized=true" \
  "stage225_renderer_submission_preview_input_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage224_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage225-228 renderer submission preview suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage225-228 renderer submission preview suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage225-228 renderer submission preview suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage225-228 renderer submission preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage225-228 renderer submission preview suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage225-228 renderer submission preview suite: runtime package build failed" >&2
  echo "cjgui stage225-228 renderer submission preview suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage224_route="$(fact_value "$stage224_packet" "next_route")"

{
  echo "stage225_228_renderer_submission_preview_suite_version=1"
  echo "stage224_render_command_refresh_readiness_decision_suite_packet=$stage224_packet"
  echo "stage224_next_route=$stage224_route"
  echo "build_log=$BUILD_LOG"
  echo "stage225_renderer_submission_preview_owner_passed=true"
  echo "stage226_renderer_submission_preview_packet_owner_passed=true"
  echo "stage227_renderer_submission_semantic_diff_explain_owner_passed=true"
  echo "stage228_renderer_submission_readiness_decision_owner_passed=true"
  echo "stage224_render_command_refresh_readiness_decision_consumed=true"
  echo "internal_render_command_packet_consumed=true"
  echo "renderer_submission_preview_materialized=true"
  echo "renderer_submission_candidate_non_submitting=true"
  echo "button_like_semantic_node_bound_to_submission_preview=true"
  echo "refreshed_render_command_packet_bound_to_submission_preview=true"
  echo "stage226_renderer_submission_preview_packet_input_prepared=true"
  echo "render_batching_packet_consumed=true"
  echo "renderer_submission_preview_packet_materialized=true"
  echo "preview_packet_bound_to_non_submitting_candidate=true"
  echo "preview_packet_bound_to_render_command_refresh_readiness=true"
  echo "renderer_submission_preview_packet_bound_to_rollback_boundary=true"
  echo "stage227_renderer_submission_semantic_diff_input_prepared=true"
  echo "renderer_submission_semantic_diff_materialized=true"
  echo "renderer_submission_explain_packet_materialized=true"
  echo "renderer_submission_rollback_ready_boundary_materialized=true"
  echo "stage228_renderer_submission_readiness_decision_input_prepared=true"
  echo "renderer_submission_preview_joined_with_packet=true"
  echo "renderer_submission_diff_explain_joined_with_rollback_boundary=true"
  echo "renderer_submission_readiness_decision_materialized=true"
  echo "stage229_renderer_backend_handoff_dry_run_input_prepared=true"
  echo "minimal_ui_framework_renderer_submission_preview_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage225_228_public_foreign_scan_passed=true"
  echo "stage225_228_forbidden_native_render_token_scan_passed=true"
  echo "stage225_228_protected_path_scan_passed=true"
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
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage229_renderer_backend_handoff_dry_run_after_submission_readiness"
  echo "stage225_228_renderer_submission_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage225-228 renderer submission preview suite: route_classification=stage228_renderer_submission_readiness_decision_ready"
echo "cjgui stage225-228 renderer submission preview suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage225-228 renderer submission preview suite: stage229_renderer_backend_handoff_dry_run_input_prepared=true"
echo "cjgui stage225-228 renderer submission preview suite: renderer_state_write=false"
