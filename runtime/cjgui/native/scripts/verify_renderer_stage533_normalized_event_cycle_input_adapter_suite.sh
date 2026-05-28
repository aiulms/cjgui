#!/usr/bin/env zsh
#
# Focused suite for stage533. It consumes stage532 normalized input events and
# verifies a reusable adapter into the shared runtime demo cycle input route.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE533_TMPDIR:-/tmp/cjgui-stage533-normalized-event-cycle-input-adapter-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage533-normalized-event-cycle-input-adapter-suite.packet"
STAGE532_SUITE_PACKET="${CJGUI_STAGE533_INPUT_PACKET:-${CJGUI_STAGE532_INPUT_EVENT_NORMALIZATION_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage533_normalized_event_cycle_input_adapter_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage533_normalized_event_cycle_input_adapter.cj"
OWNER_LOG="$TMP_DIR/stage533-normalized-event-cycle-input-adapter-owner.log"

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
    echo "cjgui stage533 normalized event cycle input adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage533 normalized event cycle input adapter suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage533 normalized event cycle input adapter suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage533 normalized event cycle input adapter suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage533 normalized event cycle input adapter suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage532_input_event_normalization_consumed=true" \
  "normalized_event_to_cycle_input_adapter_materialized=true" \
  "todo_normalized_event_action_intent_draft_materialized=true" \
  "settings_normalized_event_action_intent_draft_materialized=true" \
  "ai_generated_settings_normalized_event_action_intent_draft_materialized=true" \
  "normalized_events_bound_to_stage529_cycle_inputs=true" \
  "cycle_input_adapter_bound_to_stage530_executor_route=true" \
  "cycle_input_adapter_owner_local=true" \
  "cycle_input_adapter_non_dispatching=true" \
  "cycle_input_adapter_state_dry_run_only=true" \
  "cycle_input_adapter_render_preview_only=true" \
  "stage534_normalized_event_demo_surface_cycle_probe_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE532_SUITE_PACKET" || ! -f "$STAGE532_SUITE_PACKET" ]]; then
  echo "cjgui stage533 normalized event cycle input adapter suite: missing stage532 packet; set CJGUI_STAGE533_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage532_input_event_normalization_suite_version=1" \
  "stage531_shared_runtime_demo_cycle_host_probe_consumed=true" \
  "shared_input_event_normalization_contract_materialized=true" \
  "host_input_event_shape_ledger_materialized=true" \
  "todo_click_input_event_normalized=true" \
  "settings_toggle_input_event_normalized=true" \
  "ai_generated_settings_text_input_event_normalized=true" \
  "input_event_normalization_bound_to_runtime_demo_cycle_host_probe=true" \
  "normalized_events_bound_to_shared_runtime_demo_cycle_input_contract=true" \
  "input_event_normalization_owner_local=true" \
  "input_event_normalization_non_executing=true" \
  "input_event_normalization_non_dispatching=true" \
  "stage533_normalized_event_cycle_input_adapter_prepared=true" \
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
  require_file_fact "$STAGE532_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage533 normalized event cycle input adapter suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage533 normalized event cycle input adapter suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage533 normalized event cycle input adapter suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage533 normalized event cycle input adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage533 normalized event cycle input adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage533 normalized event cycle input adapter suite: runtime package build failed" >&2
  echo "cjgui stage533 normalized event cycle input adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage532_next_route="$(fact_value "$STAGE532_SUITE_PACKET" "next_route")"

{
  echo "stage533_normalized_event_cycle_input_adapter_suite_version=1"
  echo "stage532_input_event_normalization_suite_packet=$STAGE532_SUITE_PACKET"
  echo "stage532_next_route=$stage532_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage533_normalized_event_cycle_input_adapter_owner_passed=true"
  echo "stage532_input_event_normalization_consumed=true"
  echo "stage531_shared_runtime_demo_cycle_host_probe_consumed_transitively=true"
  echo "stage530_shared_runtime_demo_cycle_executor_consumed_transitively=true"
  echo "shared_input_event_normalization_contract_consumed=true"
  echo "normalized_input_events_consumed=true"
  echo "normalized_event_to_cycle_input_adapter_materialized=true"
  echo "todo_normalized_event_action_intent_draft_materialized=true"
  echo "settings_normalized_event_action_intent_draft_materialized=true"
  echo "ai_generated_settings_normalized_event_action_intent_draft_materialized=true"
  echo "normalized_events_bound_to_stage529_cycle_inputs=true"
  echo "cycle_input_adapter_bound_to_stage530_executor_route=true"
  echo "cycle_input_adapter_owner_local=true"
  echo "cycle_input_adapter_non_dispatching=true"
  echo "cycle_input_adapter_state_dry_run_only=true"
  echo "cycle_input_adapter_render_preview_only=true"
  echo "runtime_package_build_passed=true"
  echo "stage533_public_foreign_scan_passed=true"
  echo "stage533_forbidden_native_render_token_scan_passed=true"
  echo "stage533_protected_path_scan_passed=true"
  echo "stage534_normalized_event_demo_surface_cycle_probe_prepared=true"
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
  echo "next_route=stage534_normalized_event_demo_surface_cycle_probe_after_stage533"
  echo "stage533_normalized_event_cycle_input_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage533 normalized event cycle input adapter suite: route_classification=normalized_event_cycle_input_adapter_ready"
echo "cjgui stage533 normalized event cycle input adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage533 normalized event cycle input adapter suite: consumed_stage532=true"
echo "cjgui stage533 normalized event cycle input adapter suite: action_dispatch=false"
