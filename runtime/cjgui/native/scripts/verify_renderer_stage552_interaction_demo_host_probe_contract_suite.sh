#!/usr/bin/env zsh
#
# Focused suite for stage552. It consumes stage551 host frame receipt and
# verifies a shared checkable host probe contract across three demos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE552_TMPDIR:-/private/tmp/cjgui-stage550-stage552/stage552}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage552-interaction-demo-host-probe-contract-suite.packet"
STAGE551_SUITE_PACKET="${CJGUI_STAGE552_INPUT_PACKET:-${CJGUI_STAGE551_INTERACTION_DEMO_HOST_FRAME_ASSEMBLY_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage552_interaction_demo_host_probe_contract_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage552_interaction_demo_host_probe_contract.cj"
OWNER_LOG="$TMP_DIR/stage552-interaction-demo-host-probe-contract-owner.log"

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
    echo "cjgui stage552 interaction demo host probe contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage552 interaction demo host probe contract suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage552 interaction demo host probe contract suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage552 interaction demo host probe contract suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage552 interaction demo host probe contract suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage551_interaction_demo_host_frame_assembly_consumed=true" \
  "stage550_interaction_demo_cycle_host_integration_consumed_transitively=true" \
  "shared_interaction_demo_host_probe_contract_materialized=true" \
  "shared_interaction_demo_host_probe_helper_materialized=true" \
  "todo_interaction_demo_host_probe_input_materialized=true" \
  "settings_interaction_demo_host_probe_input_materialized=true" \
  "ai_generated_settings_interaction_demo_host_probe_input_materialized=true" \
  "interaction_demo_host_probe_bound_to_stage551_frame_receipt=true" \
  "interaction_demo_host_probe_bound_to_stage550_mount_descriptors=true" \
  "per_demo_host_probe_owner_need_reduced=true" \
  "stage553_interaction_demo_host_input_route_preview_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE551_SUITE_PACKET" || ! -f "$STAGE551_SUITE_PACKET" ]]; then
  echo "cjgui stage552 interaction demo host probe contract suite: missing stage551 packet; set CJGUI_STAGE552_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage551_interaction_demo_host_frame_assembly_suite_version=1" \
  "stage550_interaction_demo_cycle_host_integration_consumed=true" \
  "shared_interaction_demo_host_frame_assembler_materialized=true" \
  "shared_interaction_demo_host_frame_receipt_materialized=true" \
  "interaction_demo_host_focus_route_table_materialized=true" \
  "interaction_demo_host_input_route_table_materialized=true" \
  "interaction_demo_host_invalidation_ledger_materialized=true" \
  "todo_interaction_demo_host_frame_receipt_materialized=true" \
  "settings_interaction_demo_host_frame_receipt_materialized=true" \
  "ai_generated_settings_interaction_demo_host_frame_receipt_materialized=true" \
  "interaction_demo_host_frame_bound_to_stage550_mount_descriptors=true" \
  "interaction_demo_host_frame_non_publishing=true" \
  "stage552_interaction_demo_host_probe_contract_prepared=true" \
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
  require_file_fact "$STAGE551_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage552 interaction demo host probe contract suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage552 interaction demo host probe contract suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage552 interaction demo host probe contract suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage552 interaction demo host probe contract suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage552 interaction demo host probe contract suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage552 interaction demo host probe contract suite: runtime package build failed" >&2
  echo "cjgui stage552 interaction demo host probe contract suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage552_interaction_demo_host_probe_contract_suite_version=1"
  echo "stage551_interaction_demo_host_frame_assembly_suite_packet=$STAGE551_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "stage552_interaction_demo_host_probe_contract_owner_passed=true"
  echo "stage551_interaction_demo_host_frame_assembly_consumed=true"
  echo "stage550_interaction_demo_cycle_host_integration_consumed_transitively=true"
  echo "stage549_interaction_demo_cycle_surface_contract_consumed_transitively=true"
  echo "shared_interaction_demo_host_probe_contract_materialized=true"
  echo "shared_interaction_demo_host_probe_helper_materialized=true"
  echo "todo_interaction_demo_host_probe_input_materialized=true"
  echo "settings_interaction_demo_host_probe_input_materialized=true"
  echo "ai_generated_settings_interaction_demo_host_probe_input_materialized=true"
  echo "interaction_demo_host_probe_bound_to_stage551_frame_receipt=true"
  echo "interaction_demo_host_probe_bound_to_stage550_mount_descriptors=true"
  echo "interaction_demo_host_probe_checkable=true"
  echo "per_demo_host_probe_owner_need_reduced=true"
  echo "runtime_package_build_passed=true"
  echo "stage552_public_foreign_scan_passed=true"
  echo "stage552_forbidden_native_render_token_scan_passed=true"
  echo "stage552_protected_path_scan_passed=true"
  echo "stage553_interaction_demo_host_input_route_preview_prepared=true"
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
  echo "next_route=stage553_interaction_demo_host_input_route_preview_after_stage552"
  echo "stage552_interaction_demo_host_probe_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage552 interaction demo host probe contract suite: route_classification=host_probe_contract_ready"
echo "cjgui stage552 interaction demo host probe contract suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage552 interaction demo host probe contract suite: consumed_stage551=true"
echo "cjgui stage552 interaction demo host probe contract suite: renderer_submission=false"
