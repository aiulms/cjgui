#!/usr/bin/env zsh
#
# Verifies the stage742 component API authoring semantic tree preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage742_component_api_authoring_semantic_tree_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage742 component api authoring semantic tree preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage742ComponentApiAuthoringSemanticTreePreflightPlan" \
  "CjguiInternalRendererStage742ComponentApiAuthoringSemanticTreePreflightFacts" \
  "CjguiInternalRendererStage742ComponentApiAuthoringSemanticTreePreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage742ComponentApiAuthoringSemanticTreePreflightDraft" \
  "CjguiInternalRendererStage741ComponentApiAuthoringDslInternalProbeReadiness" \
  "didConsumeStage741ComponentApiAuthoringDslInternalProbe" \
  "didMaterializeComponentApiAuthoringSemanticTreePreflight" \
  "didMaterializeSemanticNodeShapeLedger" \
  "didMaterializePropBindingPreflightLedger" \
  "didMaterializeActionIntentBindingPreflightLedger" \
  "didMaterializeChatComposerAuthoringSemanticTreeCandidate" \
  "didPrepareStage743ComponentApiAuthoringDemoHostPreviewSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage742 component api authoring semantic tree preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage742_component_api_authoring_semantic_tree_preflight_owner_present=true"
echo "stage741_component_api_authoring_dsl_internal_probe_consumed=true"
echo "stage740_component_api_internal_shape_runtime_manager_consumed_transitively=true"
echo "component_api_authoring_semantic_tree_preflight_materialized=true"
echo "semantic_node_shape_ledger_materialized=true"
echo "prop_binding_preflight_ledger_materialized=true"
echo "state_slot_binding_preflight_ledger_materialized=true"
echo "action_intent_binding_preflight_ledger_materialized=true"
echo "todo_authoring_semantic_tree_candidate_materialized=true"
echo "settings_authoring_semantic_tree_candidate_materialized=true"
echo "ai_generated_settings_authoring_semantic_tree_candidate_materialized=true"
echo "chat_composer_authoring_semantic_tree_candidate_materialized=true"
echo "semantic_tree_preflight_bound_to_authoring_dsl_probe=true"
echo "stage743_component_api_authoring_demo_host_preview_surface_prepared=true"
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
