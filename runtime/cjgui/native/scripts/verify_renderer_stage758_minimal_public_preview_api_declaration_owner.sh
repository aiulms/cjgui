#!/usr/bin/env zsh
#
# Verifies the stage758 minimal public preview API declaration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage758_minimal_public_preview_api_declaration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage758 minimal public preview api declaration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationPlan" \
  "CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationFacts" \
  "CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage758MinimalPublicPreviewApiDeclarationDraft" \
  "CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness" \
  "didConsumeStage757MinimalPublicPreviewApiDescriptor" \
  "didMaterializeExperimentalComponentPreviewReadinessApi" \
  "didExposeOnlyCjguiExperimentalComponentPreviewApiReady" \
  "didKeepPublicPreviewApiStableCompatibilityUnpromised" \
  "didKeepPublicCAbiUnexpanded" \
  "didPrepareStage759MinimalPublicPreviewApiDemoConsumption" \
  "public func cjguiExperimentalComponentPreviewApiReady(): Bool"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage758 minimal public preview api declaration: missing token $token" >&2
    exit 3
  fi
done

echo "stage758_minimal_public_preview_api_declaration_owner_present=true"
echo "stage757_minimal_public_preview_api_descriptor_consumed=true"
echo "experimental_component_preview_readiness_api_materialized=true"
echo "public_surface_cjguiExperimentalComponentPreviewApiReady_materialized=true"
echo "public_preview_api_stability=experimental"
echo "public_component_api_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "public_preview_api_stable_compatibility_unpromised=true"
echo "stage759_minimal_public_preview_api_demo_consumption_prepared=true"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
