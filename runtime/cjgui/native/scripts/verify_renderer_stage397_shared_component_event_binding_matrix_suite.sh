#!/usr/bin/env zsh
#
# 维护注释：stage397 focused suite 消费 stage396 component activation render refresh packet，
# 验证 component activation contract 被扩成 shared component event binding matrix。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE397_TMPDIR:-/tmp/cjgui-stage397-shared-component-event-binding-matrix-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage397-shared-component-event-binding-matrix-suite.packet"
STAGE396_SUITE_PACKET="${CJGUI_STAGE397_INPUT_PACKET:-${CJGUI_STAGE396_SHARED_COMPONENT_EVENT_BINDING_INPUT_PACKET:-${CJGUI_STAGE396_COMPONENT_ACTIVATION_RENDER_REFRESH_PROBE_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage397_shared_component_event_binding_matrix_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage397_shared_component_event_binding_matrix.cj"
OWNER_LOG="$TMP_DIR/stage397-shared-component-event-binding-matrix-owner.log"

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
    echo "cjgui stage397 shared component event binding matrix suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage397 shared component event binding matrix suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage397 shared component event binding matrix suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage397 shared component event binding matrix suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage397 shared component event binding matrix suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage396_component_activation_render_refresh_probe_consumed=true" \
  "shared_component_event_binding_matrix_materialized=true" \
  "pointer_activation_event_bound_to_component_identity=true" \
  "keyboard_activation_event_bound_to_component_identity=true" \
  "text_submit_event_bound_to_component_identity=true" \
  "text_edit_commit_event_bound_to_component_identity=true" \
  "focus_traversal_event_bound_to_component_identity=true" \
  "component_event_matrix_bound_to_activation_slots=true" \
  "component_event_matrix_bound_to_shared_component_model=true" \
  "component_event_matrix_bound_to_stage396_render_refresh=true" \
  "component_event_owner_acceptance_gate_materialized=true" \
  "component_event_state_delta_preview_materialized=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE396_SUITE_PACKET" || ! -f "$STAGE396_SUITE_PACKET" ]]; then
  echo "cjgui stage397 shared component event binding matrix suite: missing stage396 packet; set CJGUI_STAGE397_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage396_component_activation_render_refresh_probe_suite_version=1" \
  "stage395_shared_activation_executor_component_probe_consumed=true" \
  "stage394_shared_activation_executor_demo_refresh_helper_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "component_activation_accepted_result_refresh_materialized=true" \
  "component_activation_rejected_rollback_refresh_materialized=true" \
  "todo_component_activation_result_bound_to_surface_refresh=true" \
  "settings_component_activation_result_bound_to_surface_refresh=true" \
  "ai_generated_settings_component_activation_result_bound_to_surface_refresh=true" \
  "semantic_component_activation_refresh_materialized=true" \
  "component_activation_refresh_bound_to_render_command_plan=true" \
  "component_activation_refresh_bound_to_stage394_demo_render_refresh_helper=true" \
  "component_activation_refresh_preview_only=true" \
  "stage397_shared_component_event_binding_matrix_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE396_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage397 shared component event binding matrix suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage397 shared component event binding matrix suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage397 shared component event binding matrix suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage397 shared component event binding matrix suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage397 shared component event binding matrix suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage397 shared component event binding matrix suite: runtime package build failed" >&2
  echo "cjgui stage397 shared component event binding matrix suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage396_next_route="$(fact_value "$STAGE396_SUITE_PACKET" "next_route")"

{
  echo "stage397_shared_component_event_binding_matrix_suite_version=1"
  echo "stage396_component_activation_render_refresh_probe_suite_packet=$STAGE396_SUITE_PACKET"
  echo "stage396_next_route=$stage396_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage397_shared_component_event_binding_matrix_owner_passed=true"
  echo "stage396_component_activation_render_refresh_probe_consumed=true"
  echo "stage395_shared_activation_executor_component_probe_consumed_transitively=true"
  echo "stage394_shared_activation_executor_demo_refresh_helper_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_component_event_binding_matrix_materialized=true"
  echo "pointer_activation_event_bound_to_component_identity=true"
  echo "keyboard_activation_event_bound_to_component_identity=true"
  echo "text_submit_event_bound_to_component_identity=true"
  echo "text_edit_commit_event_bound_to_component_identity=true"
  echo "focus_traversal_event_bound_to_component_identity=true"
  echo "todo_component_event_binding_slot_materialized=true"
  echo "settings_component_event_binding_slot_materialized=true"
  echo "ai_generated_settings_component_event_binding_slot_materialized=true"
  echo "component_event_matrix_bound_to_activation_slots=true"
  echo "component_event_matrix_bound_to_shared_component_model=true"
  echo "component_event_matrix_bound_to_stage396_render_refresh=true"
  echo "component_event_owner_acceptance_gate_materialized=true"
  echo "component_event_state_delta_preview_materialized=true"
  echo "component_event_matrix_owner_local=true"
  echo "component_event_matrix_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage397_public_foreign_scan_passed=true"
  echo "stage397_forbidden_native_render_token_scan_passed=true"
  echo "stage397_protected_path_scan_passed=true"
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
  echo "component_event_binding_matrix_dry_run=true"
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
  echo "stage398_component_event_sequence_render_refresh_probe_prepared=true"
  echo "next_route=stage398_component_event_sequence_render_refresh_probe_after_stage397"
  echo "stage397_shared_component_event_binding_matrix_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage397 shared component event binding matrix suite: route_classification=component_event_binding_matrix_ready"
echo "cjgui stage397 shared component event binding matrix suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage397 shared component event binding matrix suite: consumed_stage396=true"
echo "cjgui stage397 shared component event binding matrix suite: renderer_state_write=false"
