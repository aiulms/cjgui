#!/usr/bin/env zsh
#
# Focused suite for stage549. It consumes stage548 execution receipts and
# verifies a shared demo cycle surface contract across three demo surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE549_TMPDIR:-/tmp/cjgui-stage549-interaction-demo-cycle-surface-contract-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage549-interaction-demo-cycle-surface-contract-suite.packet"
STAGE548_SUITE_PACKET="${CJGUI_STAGE549_INPUT_PACKET:-${CJGUI_STAGE548_INTERACTION_CYCLE_EXECUTION_RECEIPT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage549_interaction_demo_cycle_surface_contract_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage549_interaction_demo_cycle_surface_contract.cj"
OWNER_LOG="$TMP_DIR/stage549-interaction-demo-cycle-surface-contract-owner.log"

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
    echo "cjgui stage549 interaction demo cycle surface contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage549 interaction demo cycle surface contract suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage548_interaction_cycle_execution_receipt_consumed=true" \
  "shared_interaction_demo_cycle_surface_contract_materialized=true" \
  "shared_interaction_demo_cycle_surface_helper_materialized=true" \
  "todo_interaction_demo_cycle_surface_materialized=true" \
  "settings_interaction_demo_cycle_surface_materialized=true" \
  "ai_generated_settings_interaction_demo_cycle_surface_materialized=true" \
  "interaction_demo_cycle_surface_bound_to_stage548_execution_receipts=true" \
  "interaction_demo_cycle_surface_bound_to_stage546_runtime_contract=true" \
  "interaction_demo_cycle_surface_bound_to_stage540_host_inspection=true" \
  "same_shape_interaction_cycle_owner_probe_need_reduced=true" \
  "stage550_component_runtime_interaction_demo_cycle_host_integration_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE548_SUITE_PACKET" || ! -f "$STAGE548_SUITE_PACKET" ]]; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: missing stage548 packet; set CJGUI_STAGE549_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage548_interaction_cycle_execution_receipt_suite_version=1" \
  "stage547_interaction_input_event_cycle_probe_consumed=true" \
  "stage546_interaction_demo_surface_runtime_contract_consumed_transitively=true" \
  "shared_interaction_cycle_dry_run_executor_materialized=true" \
  "shared_interaction_cycle_execution_receipt_materialized=true" \
  "interaction_event_state_render_layout_order_ledger_materialized=true" \
  "todo_interaction_cycle_execution_receipt_materialized=true" \
  "settings_interaction_cycle_execution_receipt_materialized=true" \
  "ai_generated_settings_interaction_cycle_execution_receipt_materialized=true" \
  "interaction_cycle_execution_bound_to_stage546_runtime_contract=true" \
  "interaction_cycle_execution_non_dispatching=true" \
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
  require_file_fact "$STAGE548_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage549 interaction demo cycle surface contract suite: runtime package build failed" >&2
  echo "cjgui stage549 interaction demo cycle surface contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage548_next_route="$(fact_value "$STAGE548_SUITE_PACKET" "next_route")"

{
  echo "stage549_interaction_demo_cycle_surface_contract_suite_version=1"
  echo "stage548_interaction_cycle_execution_receipt_suite_packet=$STAGE548_SUITE_PACKET"
  echo "stage548_next_route=$stage548_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage549_interaction_demo_cycle_surface_contract_owner_passed=true"
  echo "stage548_interaction_cycle_execution_receipt_consumed=true"
  echo "stage547_interaction_input_event_cycle_probe_consumed_transitively=true"
  echo "stage546_interaction_demo_surface_runtime_contract_consumed_transitively=true"
  echo "stage534_normalized_event_demo_surface_cycle_probe_consumed_transitively=true"
  echo "shared_interaction_demo_cycle_surface_contract_materialized=true"
  echo "shared_interaction_demo_cycle_surface_helper_materialized=true"
  echo "todo_interaction_demo_cycle_surface_materialized=true"
  echo "settings_interaction_demo_cycle_surface_materialized=true"
  echo "ai_generated_settings_interaction_demo_cycle_surface_materialized=true"
  echo "interaction_demo_cycle_surface_bound_to_stage548_execution_receipts=true"
  echo "interaction_demo_cycle_surface_bound_to_stage546_runtime_contract=true"
  echo "interaction_demo_cycle_surface_bound_to_stage540_host_inspection=true"
  echo "interaction_demo_cycle_surface_checkable=true"
  echo "same_shape_interaction_cycle_owner_probe_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage549_public_foreign_scan_passed=true"
  echo "stage549_forbidden_native_render_token_scan_passed=true"
  echo "stage549_protected_path_scan_passed=true"
  echo "stage550_component_runtime_interaction_demo_cycle_host_integration_prepared=true"
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
  echo "next_route=stage550_component_runtime_interaction_demo_cycle_host_integration_after_stage549"
  echo "stage549_interaction_demo_cycle_surface_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage549 interaction demo cycle surface contract suite: route_classification=interaction_demo_cycle_surface_contract_ready"
echo "cjgui stage549 interaction demo cycle surface contract suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage549 interaction demo cycle surface contract suite: consumed_stage548=true"
echo "cjgui stage549 interaction demo cycle surface contract suite: renderer_submission=false"
