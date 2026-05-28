#!/usr/bin/env zsh
#
# Focused suite for stage550. It consumes stage549 demo cycle surfaces and
# verifies shared owner-local host mount descriptors across three demos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE550_TMPDIR:-/private/tmp/cjgui-stage550-stage552/stage550}"
SUITE_PACKET="$TMP_DIR/stage550-interaction-demo-cycle-host-integration-suite.packet"
STAGE549_SUITE_PACKET="${CJGUI_STAGE550_INPUT_PACKET:-${CJGUI_STAGE549_INTERACTION_DEMO_CYCLE_SURFACE_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage550_interaction_demo_cycle_host_integration_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage550_interaction_demo_cycle_host_integration.cj"
OWNER_LOG="$TMP_DIR/stage550-interaction-demo-cycle-host-integration-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage550 interaction demo cycle host integration suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage550 interaction demo cycle host integration suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage550 interaction demo cycle host integration suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage550 interaction demo cycle host integration suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage550 interaction demo cycle host integration suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage549_interaction_demo_cycle_surface_contract_consumed=true" \
  "stage540_component_runtime_demo_host_inspection_consumed_transitively=true" \
  "shared_interaction_demo_host_mount_contract_materialized=true" \
  "shared_interaction_demo_host_mount_helper_materialized=true" \
  "todo_interaction_demo_host_mount_descriptor_materialized=true" \
  "settings_interaction_demo_host_mount_descriptor_materialized=true" \
  "ai_generated_settings_interaction_demo_host_mount_descriptor_materialized=true" \
  "interaction_demo_host_mounts_bound_to_stage549_cycle_surfaces=true" \
  "interaction_demo_host_mounts_bound_to_stage540_host_inspection=true" \
  "per_demo_host_integration_duplication_reduced=true" \
  "stage551_interaction_demo_host_frame_assembly_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE549_SUITE_PACKET" || ! -f "$STAGE549_SUITE_PACKET" ]]; then
  echo "cjgui stage550 interaction demo cycle host integration suite: missing stage549 packet; set CJGUI_STAGE550_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage549_interaction_demo_cycle_surface_contract_suite_version=1" \
  "stage548_interaction_cycle_execution_receipt_consumed=true" \
  "shared_interaction_demo_cycle_surface_contract_materialized=true" \
  "shared_interaction_demo_cycle_surface_helper_materialized=true" \
  "todo_interaction_demo_cycle_surface_materialized=true" \
  "settings_interaction_demo_cycle_surface_materialized=true" \
  "ai_generated_settings_interaction_demo_cycle_surface_materialized=true" \
  "interaction_demo_cycle_surface_bound_to_stage548_execution_receipts=true" \
  "interaction_demo_cycle_surface_bound_to_stage546_runtime_contract=true" \
  "interaction_demo_cycle_surface_bound_to_stage540_host_inspection=true" \
  "stage550_component_runtime_interaction_demo_cycle_host_integration_prepared=true" \
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
  require_file_fact "$STAGE549_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage550 interaction demo cycle host integration suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage550 interaction demo cycle host integration suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage550 interaction demo cycle host integration suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage550 interaction demo cycle host integration suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage550_interaction_demo_cycle_host_integration_suite_version=1"
  echo "stage549_interaction_demo_cycle_surface_contract_suite_packet=$STAGE549_SUITE_PACKET"
  echo "stage550_interaction_demo_cycle_host_integration_owner_passed=true"
  echo "stage549_interaction_demo_cycle_surface_contract_consumed=true"
  echo "stage548_interaction_cycle_execution_receipt_consumed_transitively=true"
  echo "stage540_component_runtime_demo_host_inspection_consumed_transitively=true"
  echo "shared_interaction_demo_host_mount_contract_materialized=true"
  echo "shared_interaction_demo_host_mount_helper_materialized=true"
  echo "todo_interaction_demo_host_mount_descriptor_materialized=true"
  echo "settings_interaction_demo_host_mount_descriptor_materialized=true"
  echo "ai_generated_settings_interaction_demo_host_mount_descriptor_materialized=true"
  echo "interaction_demo_host_mounts_bound_to_stage549_cycle_surfaces=true"
  echo "interaction_demo_host_mounts_bound_to_stage540_host_inspection=true"
  echo "interaction_demo_host_mounts_checkable=true"
  echo "per_demo_host_integration_duplication_reduced=true"
  echo "stage550_public_foreign_scan_passed=true"
  echo "stage550_forbidden_native_render_token_scan_passed=true"
  echo "stage550_protected_path_scan_passed=true"
  echo "stage551_interaction_demo_host_frame_assembly_prepared=true"
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
  echo "next_route=stage551_interaction_demo_host_frame_assembly_after_stage550"
  echo "stage550_interaction_demo_cycle_host_integration_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage550 interaction demo cycle host integration suite: route_classification=host_mount_contract_ready"
echo "cjgui stage550 interaction demo cycle host integration suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage550 interaction demo cycle host integration suite: consumed_stage549=true"
echo "cjgui stage550 interaction demo cycle host integration suite: renderer_submission=false"
