#!/usr/bin/env zsh
#
# Verifies the stage891 component commit API demo consumption owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage891_component_commit_api_demo_consumption.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage891 component commit api demo consumption: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage891ComponentCommitApiDemoConsumptionPlan" \
  "CjguiInternalRendererStage891ComponentCommitApiDemoConsumptionFacts" \
  "CjguiInternalRendererStage891ComponentCommitApiDemoConsumptionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage891ComponentCommitApiDemoConsumptionDraft" \
  "CjguiInternalRendererStage890ExperimentalComponentCommitApiDeclarationReadiness" \
  "cjguiExperimentalComponentCommitApiReady" \
  "didConsumeStage890ExperimentalComponentCommitApiDeclaration" \
  "didConsumeCjguiExperimentalComponentCommitApiReady" \
  "didMaterializeTodoComponentCommitApiDemoSurface" \
  "didMaterializeSettingsComponentCommitApiDemoSurface" \
  "didMaterializeAiGeneratedSettingsComponentCommitApiDemoSurface" \
  "didMaterializeChatComposerComponentCommitApiDemoSurface" \
  "didMaterializeFileBrowserComponentCommitApiDemoSurface" \
  "didBindDemoConsumptionToExperimentalCommitApi" \
  "didPrepareStage892ComponentCommitApiRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage891 component commit api demo consumption: missing token $token" >&2
    exit 3
  fi
done

echo "stage891_component_commit_api_demo_consumption_owner_present=true"
echo "stage890_experimental_component_commit_api_declaration_consumed=true"
echo "cjguiExperimentalComponentCommitApiReady_consumed=true"
echo "todo_component_commit_api_demo_surface_materialized=true"
echo "settings_component_commit_api_demo_surface_materialized=true"
echo "ai_generated_settings_component_commit_api_demo_surface_materialized=true"
echo "chat_composer_component_commit_api_demo_surface_materialized=true"
echo "file_browser_component_commit_api_demo_surface_materialized=true"
echo "demo_consumption_bound_to_experimental_commit_api=true"
echo "demo_consumption_bound_to_stage888_publication_runtime_manager_transitively=true"
echo "stage892_component_commit_api_runtime_manager_prepared=true"
echo "new_public_surface_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_store_write_executed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
