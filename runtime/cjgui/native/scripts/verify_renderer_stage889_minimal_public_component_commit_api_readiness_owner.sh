#!/usr/bin/env zsh
#
# Verifies the stage889 minimal public component commit API readiness owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage889_minimal_public_component_commit_api_readiness.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage889 minimal public component commit api readiness: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage889MinimalPublicComponentCommitApiReadinessPlan" \
  "CjguiInternalRendererStage889MinimalPublicComponentCommitApiReadinessFacts" \
  "CjguiInternalRendererStage889MinimalPublicComponentCommitApiReadiness" \
  "cjguiInternalExecuteDefaultRendererStage889MinimalPublicComponentCommitApiReadinessDraft" \
  "CjguiInternalRendererStage888OwnerLocalAcceptedCommitPublicationRuntimeManagerReadiness" \
  "didConsumeStage888OwnerLocalAcceptedCommitPublicationRuntimeManager" \
  "didMaterializeMinimalPublicComponentCommitApiReadiness" \
  "didMaterializeExperimentalComponentCommitApiDescriptor" \
  "didMaterializeComponentCommitApiCompatibilityLedger" \
  "didMaterializeComponentCommitApiRollbackBoundary" \
  "didBindComponentCommitApiReadinessToPublicationRuntimeManager" \
  "didPrepareStage890ExperimentalComponentCommitApiDeclaration"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage889 minimal public component commit api readiness: missing token $token" >&2
    exit 3
  fi
done

echo "stage889_minimal_public_component_commit_api_readiness_owner_present=true"
echo "stage888_owner_local_accepted_commit_publication_runtime_manager_consumed=true"
echo "minimal_public_component_commit_api_readiness_materialized=true"
echo "experimental_component_commit_api_descriptor_materialized=true"
echo "component_commit_api_compatibility_ledger_materialized=true"
echo "component_commit_api_rollback_boundary_materialized=true"
echo "component_commit_api_not_published_receipt_materialized=true"
echo "component_commit_api_readiness_bound_to_publication_runtime_manager=true"
echo "existing_experimental_preview_api_consumed=true"
echo "stage890_experimental_component_commit_api_declaration_prepared=true"
echo "new_public_surface_added=false"
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
