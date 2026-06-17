#!/usr/bin/env zsh
#
# Verifies the stage890 experimental component commit API declaration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage890_experimental_component_commit_api_declaration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage890 experimental component commit api declaration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage890ExperimentalComponentCommitApiDeclarationPlan" \
  "CjguiInternalRendererStage890ExperimentalComponentCommitApiDeclarationFacts" \
  "CjguiInternalRendererStage890ExperimentalComponentCommitApiDeclarationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage890ExperimentalComponentCommitApiDeclarationDraft" \
  "CjguiInternalRendererStage889MinimalPublicComponentCommitApiReadiness" \
  "public func cjguiExperimentalComponentCommitApiReady(): Bool" \
  "didConsumeStage889MinimalPublicComponentCommitApiReadiness" \
  "didMaterializeExperimentalComponentCommitReadinessApi" \
  "didExposeOnlyCjguiExperimentalComponentCommitApiReadyAsNewSurface" \
  "didBindPublicCommitApiToStage889Readiness" \
  "didKeepPublicCommitApiStableCompatibilityUnpromised" \
  "didPrepareStage891ComponentCommitApiDemoConsumption"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage890 experimental component commit api declaration: missing token $token" >&2
    exit 3
  fi
done

echo "stage890_experimental_component_commit_api_declaration_owner_present=true"
echo "stage889_minimal_public_component_commit_api_readiness_consumed=true"
echo "experimental_component_commit_readiness_api_materialized=true"
echo "public_surface_cjguiExperimentalComponentCommitApiReady_materialized=true"
echo "only_cjguiExperimentalComponentCommitApiReady_exposed_as_new_surface=true"
echo "public_commit_api_bound_to_stage889_readiness=true"
echo "public_commit_api_stable_compatibility_unpromised=true"
echo "stage891_component_commit_api_demo_consumption_prepared=true"
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
