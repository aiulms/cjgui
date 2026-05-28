#!/usr/bin/env zsh
#
# Focused suite for stage547. It consumes the stage546 runtime contract packet
# and verifies the normalized input-event cycle probe re-entry.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE547_TMPDIR:-/tmp/cjgui-stage547-interaction-input-event-cycle-probe-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage547-interaction-input-event-cycle-probe-suite.packet"
STAGE546_SUITE_PACKET="${CJGUI_STAGE547_INPUT_PACKET:-${CJGUI_STAGE546_COMPONENT_RUNTIME_INTERACTION_DEMO_SURFACE_RUNTIME_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage547_interaction_input_event_cycle_probe_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage547_interaction_input_event_cycle_probe.cj"
OWNER_LOG="$TMP_DIR/stage547-interaction-input-event-cycle-probe-owner.log"

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
    echo "cjgui stage547 interaction input event cycle probe suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage547 interaction input event cycle probe suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage547 interaction input event cycle probe suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage547 interaction input event cycle probe suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage547 interaction input event cycle probe suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage546_interaction_demo_surface_runtime_contract_consumed=true" \
  "stage534_normalized_event_demo_surface_cycle_probe_consumed=true" \
  "shared_interaction_input_event_cycle_probe_contract_materialized=true" \
  "shared_interaction_input_event_cycle_probe_helper_materialized=true" \
  "todo_interaction_input_event_cycle_probe_input_materialized=true" \
  "settings_interaction_input_event_cycle_probe_input_materialized=true" \
  "ai_generated_settings_interaction_input_event_cycle_probe_input_materialized=true" \
  "interaction_runtime_inputs_bound_to_normalized_event_cycle_probe=true" \
  "per_demo_input_cycle_probe_duplication_reduced=true" \
  "stage548_interaction_cycle_execution_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE546_SUITE_PACKET" || ! -f "$STAGE546_SUITE_PACKET" ]]; then
  echo "cjgui stage547 interaction input event cycle probe suite: missing stage546 packet; set CJGUI_STAGE547_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage546_component_runtime_interaction_demo_surface_runtime_contract_suite_version=1" \
  "stage545_component_runtime_interaction_layout_measurement_executor_consumed=true" \
  "shared_component_runtime_interaction_demo_surface_runtime_contract_materialized=true" \
  "shared_component_runtime_interaction_demo_surface_runtime_helper_materialized=true" \
  "todo_interaction_checkable_demo_surface_input_materialized=true" \
  "settings_interaction_checkable_demo_surface_input_materialized=true" \
  "ai_generated_settings_interaction_checkable_demo_surface_input_materialized=true" \
  "demo_surface_runtime_contract_bound_to_layout_measurement_receipts=true" \
  "demo_surface_runtime_contract_bound_to_stage543_refresh_receipts=true" \
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
  require_file_fact "$STAGE546_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage547 interaction input event cycle probe suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage547 interaction input event cycle probe suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage547 interaction input event cycle probe suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage547 interaction input event cycle probe suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage547 interaction input event cycle probe suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage547 interaction input event cycle probe suite: runtime package build failed" >&2
  echo "cjgui stage547 interaction input event cycle probe suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage546_next_route="$(fact_value "$STAGE546_SUITE_PACKET" "next_route")"

{
  echo "stage547_interaction_input_event_cycle_probe_suite_version=1"
  echo "stage546_component_runtime_interaction_demo_surface_runtime_contract_suite_packet=$STAGE546_SUITE_PACKET"
  echo "stage546_next_route=$stage546_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage547_interaction_input_event_cycle_probe_owner_passed=true"
  echo "stage546_interaction_demo_surface_runtime_contract_consumed=true"
  echo "stage534_normalized_event_demo_surface_cycle_probe_consumed=true"
  echo "shared_interaction_input_event_cycle_probe_contract_materialized=true"
  echo "shared_interaction_input_event_cycle_probe_helper_materialized=true"
  echo "todo_interaction_input_event_cycle_probe_input_materialized=true"
  echo "settings_interaction_input_event_cycle_probe_input_materialized=true"
  echo "ai_generated_settings_interaction_input_event_cycle_probe_input_materialized=true"
  echo "interaction_runtime_inputs_bound_to_normalized_event_cycle_probe=true"
  echo "interaction_cycle_probe_bound_to_stage546_runtime_contract=true"
  echo "interaction_cycle_probe_bound_to_stage534_normalized_events=true"
  echo "interaction_cycle_probe_checkable=true"
  echo "per_demo_input_cycle_probe_duplication_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage547_public_foreign_scan_passed=true"
  echo "stage547_forbidden_native_render_token_scan_passed=true"
  echo "stage547_protected_path_scan_passed=true"
  echo "stage548_interaction_cycle_execution_receipt_prepared=true"
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
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage548_interaction_cycle_execution_receipt_after_stage547"
  echo "stage547_interaction_input_event_cycle_probe_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage547 interaction input event cycle probe suite: route_classification=interaction_input_event_cycle_probe_ready"
echo "cjgui stage547 interaction input event cycle probe suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage547 interaction input event cycle probe suite: consumed_stage546=true"
echo "cjgui stage547 interaction input event cycle probe suite: renderer_submission=false"
