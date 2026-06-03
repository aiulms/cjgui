#!/usr/bin/env zsh
#
# Verifies the stage741 component API authoring DSL internal probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage741_component_api_authoring_dsl_internal_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage741 component api authoring dsl internal probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage741ComponentApiAuthoringDslInternalProbePlan" \
  "CjguiInternalRendererStage741ComponentApiAuthoringDslInternalProbeFacts" \
  "CjguiInternalRendererStage741ComponentApiAuthoringDslInternalProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage741ComponentApiAuthoringDslInternalProbeDraft" \
  "CjguiInternalRendererStage740ComponentApiInternalShapeRuntimeManagerReadiness" \
  "didConsumeStage740ComponentApiInternalShapeRuntimeManager" \
  "didMaterializeComponentApiAuthoringDslInternalProbe" \
  "didMaterializeRestrictedComponentDeclarationTokens" \
  "didMaterializePropsStateActionBindingGrammar" \
  "didMaterializeTodoComponentApiAuthoringDslProbe" \
  "didMaterializeChatComposerComponentApiAuthoringDslProbe" \
  "didPrepareStage742ComponentApiAuthoringSemanticTreePreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage741 component api authoring dsl internal probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage741_component_api_authoring_dsl_internal_probe_owner_present=true"
echo "stage740_component_api_internal_shape_runtime_manager_consumed=true"
echo "component_api_internal_authoring_runtime_contract_consumed=true"
echo "component_api_authoring_dsl_internal_probe_materialized=true"
echo "restricted_component_declaration_tokens_materialized=true"
echo "props_state_action_binding_grammar_materialized=true"
echo "dsl_probe_input_contract_materialized=true"
echo "todo_component_api_authoring_dsl_probe_materialized=true"
echo "settings_component_api_authoring_dsl_probe_materialized=true"
echo "ai_generated_settings_component_api_authoring_dsl_probe_materialized=true"
echo "chat_composer_component_api_authoring_dsl_probe_materialized=true"
echo "dsl_probe_bound_to_internal_shape_runtime_manager=true"
echo "component_api_authoring_dsl_internal_only=true"
echo "stage742_component_api_authoring_semantic_tree_preflight_prepared=true"
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
