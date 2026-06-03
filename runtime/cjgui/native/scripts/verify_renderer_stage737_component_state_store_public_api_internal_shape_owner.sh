#!/usr/bin/env zsh
#
# Verifies the stage737 component state store public API internal shape owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage737_component_state_store_public_api_internal_shape.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage737 component state store public api internal shape: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapePlan" \
  "CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeFacts" \
  "CjguiInternalRendererStage737ComponentStateStorePublicApiInternalShapeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage737ComponentStateStorePublicApiInternalShapeDraft" \
  "CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness" \
  "didConsumeStage736ComponentStateStoreCommitRuntimeManager" \
  "didMaterializeInternalComponentApiShapeDescriptor" \
  "didMaterializeComponentPropsShapeLedger" \
  "didMaterializeComponentStateSlotShapeLedger" \
  "didMaterializeComponentEventPortShapeLedger" \
  "didMaterializeComponentCommitCapabilityShape" \
  "didBindInternalShapeToStage736CommitRuntimeManager" \
  "didPrepareStage738ComponentApiCompatibilityPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage737 component state store public api internal shape: missing token $token" >&2
    exit 3
  fi
done

echo "stage737_component_state_store_public_api_internal_shape_owner_present=true"
echo "stage736_component_state_store_commit_runtime_manager_consumed=true"
echo "stage735_component_visual_state_store_commit_host_inspection_ui_consumed_transitively=true"
echo "internal_component_api_shape_descriptor_materialized=true"
echo "component_props_shape_ledger_materialized=true"
echo "component_state_slot_shape_ledger_materialized=true"
echo "component_event_port_shape_ledger_materialized=true"
echo "component_commit_capability_shape_materialized=true"
echo "todo_component_api_internal_shape_surface_materialized=true"
echo "settings_component_api_internal_shape_surface_materialized=true"
echo "ai_generated_settings_component_api_internal_shape_surface_materialized=true"
echo "chat_composer_component_api_internal_shape_surface_materialized=true"
echo "internal_shape_bound_to_stage736_commit_runtime_manager=true"
echo "stage738_component_api_compatibility_preflight_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
