#!/usr/bin/env zsh
#
# Focused suite for stage468. It consumes stage467 state update candidates and
# verifies a reusable state -> RenderCommand refresh bridge for refreshed surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE468_TMPDIR:-/tmp/cjgui-stage468-shared-component-runtime-visual-refresh-state-render-command-refresh-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage468-shared-component-runtime-visual-refresh-state-render-command-refresh-suite.packet"
STAGE467_SUITE_PACKET="${CJGUI_STAGE468_INPUT_PACKET:-${CJGUI_STAGE467_SHARED_COMPONENT_RUNTIME_VISUAL_REFRESH_ACTION_STATE_UPDATE_DRY_RUN_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage468_shared_component_runtime_visual_refresh_state_render_command_refresh.cj"
OWNER_LOG="$TMP_DIR/stage468-shared-component-runtime-visual-refresh-state-render-command-refresh-owner.log"

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
    echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run_consumed=true" \
  "shared_component_runtime_visual_refresh_action_state_update_dry_run_consumed=true" \
  "todo_runtime_visual_refresh_state_update_candidate_consumed=true" \
  "settings_runtime_visual_refresh_state_update_candidate_consumed=true" \
  "ai_generated_settings_runtime_visual_refresh_state_update_candidate_consumed=true" \
  "shared_component_runtime_visual_refresh_state_render_command_refresh_materialized=true" \
  "todo_runtime_visual_refresh_render_command_probe_input_materialized=true" \
  "settings_runtime_visual_refresh_render_command_probe_input_materialized=true" \
  "ai_generated_settings_runtime_visual_refresh_render_command_probe_input_materialized=true" \
  "visual_refresh_state_update_to_render_command_refresh_bound=true" \
  "render_command_refresh_to_visual_refresh_demo_surface_probe_bound=true" \
  "visual_refresh_state_render_command_bridge_reusable=true" \
  "visual_refresh_state_render_command_bridge_preview_only=true" \
  "stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE467_SUITE_PACKET" || ! -f "$STAGE467_SUITE_PACKET" ]]; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: missing stage467 packet; set CJGUI_STAGE468_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run_suite_version=1" \
  "stage466_shared_component_runtime_visual_refresh_input_action_adapter_consumed=true" \
  "shared_component_runtime_visual_refresh_action_state_update_dry_run_materialized=true" \
  "todo_runtime_visual_refresh_state_update_candidate_materialized=true" \
  "settings_runtime_visual_refresh_state_update_candidate_materialized=true" \
  "ai_generated_settings_runtime_visual_refresh_state_update_candidate_materialized=true" \
  "visual_refresh_action_intent_to_state_update_dry_run_bound=true" \
  "visual_refresh_probe_input_to_state_update_dry_run_bound=true" \
  "visual_refresh_state_rollback_preview_materialized=true" \
  "visual_refresh_state_update_owner_local=true" \
  "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_prepared=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE467_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: runtime package build failed" >&2
  echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage467_next_route="$(fact_value "$STAGE467_SUITE_PACKET" "next_route")"

{
  echo "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_suite_version=1"
  echo "stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run_suite_packet=$STAGE467_SUITE_PACKET"
  echo "stage467_next_route=$stage467_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_owner_passed=true"
  echo "stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run_consumed=true"
  echo "stage466_shared_component_runtime_visual_refresh_input_action_adapter_consumed_transitively=true"
  echo "stage465_shared_component_runtime_demo_surface_visual_refresh_receipt_consumed_transitively=true"
  echo "shared_component_runtime_visual_refresh_action_state_update_dry_run_consumed=true"
  echo "todo_runtime_visual_refresh_state_update_candidate_consumed=true"
  echo "settings_runtime_visual_refresh_state_update_candidate_consumed=true"
  echo "ai_generated_settings_runtime_visual_refresh_state_update_candidate_consumed=true"
  echo "shared_component_runtime_visual_refresh_state_render_command_refresh_materialized=true"
  echo "todo_runtime_visual_refresh_render_command_probe_input_materialized=true"
  echo "settings_runtime_visual_refresh_render_command_probe_input_materialized=true"
  echo "ai_generated_settings_runtime_visual_refresh_render_command_probe_input_materialized=true"
  echo "visual_refresh_state_update_to_render_command_refresh_bound=true"
  echo "render_command_refresh_to_visual_refresh_demo_surface_probe_bound=true"
  echo "visual_refresh_state_render_command_bridge_reusable=true"
  echo "visual_refresh_state_render_command_bridge_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage468_public_foreign_scan_passed=true"
  echo "stage468_forbidden_native_render_token_scan_passed=true"
  echo "stage468_protected_path_scan_passed=true"
  echo "stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "text_shaping_enabled=false"
  echo "focus_manager_enabled=false"
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
  echo "next_route=stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt_after_stage468"
  echo "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: route_classification=shared_component_runtime_visual_refresh_state_render_command_refresh_ready"
echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: consumed_stage467=true"
echo "cjgui stage468 shared component runtime visual refresh state RenderCommand refresh suite: renderer_submission=false"
