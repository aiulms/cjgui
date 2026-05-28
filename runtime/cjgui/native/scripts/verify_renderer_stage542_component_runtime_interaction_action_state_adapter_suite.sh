#!/usr/bin/env zsh
#
# Focused suite for stage542. It consumes stage541 interaction targets and
# verifies a shared non-dispatching action/state adapter contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE542_TMPDIR:-/tmp/cjgui-stage542-component-runtime-interaction-action-state-adapter-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage542-component-runtime-interaction-action-state-adapter-suite.packet"
STAGE541_SUITE_PACKET="${CJGUI_STAGE542_INPUT_PACKET:-${CJGUI_STAGE541_COMPONENT_RUNTIME_INTERACTION_BRIDGE_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage542_component_runtime_interaction_action_state_adapter_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage542_component_runtime_interaction_action_state_adapter.cj"
OWNER_LOG="$TMP_DIR/stage542-component-runtime-interaction-action-state-adapter-owner.log"

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
    echo "cjgui stage542 component runtime interaction action state adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage542 component runtime interaction action state adapter suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage541_component_runtime_interaction_bridge_consumed=true" \
  "component_runtime_interaction_targets_consumed=true" \
  "shared_component_runtime_interaction_action_state_adapter_materialized=true" \
  "shared_component_runtime_interaction_action_state_contract_materialized=true" \
  "todo_interaction_action_state_candidate_materialized=true" \
  "settings_interaction_action_state_candidate_materialized=true" \
  "ai_generated_settings_interaction_action_state_candidate_materialized=true" \
  "action_state_adapter_bound_to_interaction_targets=true" \
  "action_state_adapter_non_dispatching=true" \
  "interaction_state_updates_owner_local_dry_run=true" \
  "per_demo_action_state_adapter_duplication_reduced=true" \
  "stage543_component_runtime_interaction_state_render_refresh_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE541_SUITE_PACKET" || ! -f "$STAGE541_SUITE_PACKET" ]]; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: missing stage541 packet; set CJGUI_STAGE542_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage541_component_runtime_interaction_bridge_suite_version=1" \
  "stage540_component_runtime_demo_host_inspection_contract_consumed=true" \
  "shared_component_runtime_interaction_bridge_contract_materialized=true" \
  "shared_component_runtime_interaction_target_ledger_materialized=true" \
  "todo_component_runtime_interaction_target_materialized=true" \
  "settings_component_runtime_interaction_target_materialized=true" \
  "ai_generated_settings_component_runtime_interaction_target_materialized=true" \
  "interaction_bridge_bound_to_host_inspection_inputs=true" \
  "interaction_bridge_bound_to_stage537_event_refresh_executor=true" \
  "owner_acceptance_granted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE541_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage542 component runtime interaction action state adapter suite: runtime package build failed" >&2
  echo "cjgui stage542 component runtime interaction action state adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage541_next_route="$(fact_value "$STAGE541_SUITE_PACKET" "next_route")"

{
  echo "stage542_component_runtime_interaction_action_state_adapter_suite_version=1"
  echo "stage541_component_runtime_interaction_bridge_suite_packet=$STAGE541_SUITE_PACKET"
  echo "stage541_next_route=$stage541_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage542_component_runtime_interaction_action_state_adapter_owner_passed=true"
  echo "stage541_component_runtime_interaction_bridge_consumed=true"
  echo "stage540_component_runtime_demo_host_inspection_contract_consumed_transitively=true"
  echo "stage537_event_refresh_surface_executor_consumed_transitively=true"
  echo "component_runtime_interaction_targets_consumed=true"
  echo "shared_component_runtime_interaction_action_state_adapter_materialized=true"
  echo "shared_component_runtime_interaction_action_state_contract_materialized=true"
  echo "todo_interaction_action_state_candidate_materialized=true"
  echo "settings_interaction_action_state_candidate_materialized=true"
  echo "ai_generated_settings_interaction_action_state_candidate_materialized=true"
  echo "action_state_adapter_bound_to_interaction_targets=true"
  echo "action_state_adapter_bound_to_host_inspection_bridge=true"
  echo "action_state_adapter_non_dispatching=true"
  echo "interaction_state_updates_owner_local_dry_run=true"
  echo "per_demo_action_state_adapter_duplication_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage542_public_foreign_scan_passed=true"
  echo "stage542_forbidden_native_render_token_scan_passed=true"
  echo "stage542_protected_path_scan_passed=true"
  echo "stage543_component_runtime_interaction_state_render_refresh_executor_prepared=true"
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
  echo "next_route=stage543_component_runtime_interaction_state_render_refresh_executor_after_stage542"
  echo "stage542_component_runtime_interaction_action_state_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage542 component runtime interaction action state adapter suite: route_classification=component_runtime_interaction_action_state_adapter_ready"
echo "cjgui stage542 component runtime interaction action state adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage542 component runtime interaction action state adapter suite: consumed_stage541=true"
echo "cjgui stage542 component runtime interaction action state adapter suite: renderer_submission=false"
