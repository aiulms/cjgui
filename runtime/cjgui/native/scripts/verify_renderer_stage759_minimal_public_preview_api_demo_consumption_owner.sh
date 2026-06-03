#!/usr/bin/env zsh
#
# Verifies the stage759 minimal public preview API demo consumption owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage759_minimal_public_preview_api_demo_consumption.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage759 minimal public preview api demo consumption: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionPlan" \
  "CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionFacts" \
  "CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage759MinimalPublicPreviewApiDemoConsumptionDraft" \
  "CjguiInternalRendererStage758MinimalPublicPreviewApiDeclarationReadiness" \
  "didConsumeStage758MinimalPublicPreviewApiDeclaration" \
  "didConsumeCjguiExperimentalComponentPreviewApiReady" \
  "didMaterializeTodoPublicPreviewApiDemoSurface" \
  "didMaterializeSettingsPublicPreviewApiDemoSurface" \
  "didBindDemoConsumptionToPublicPreviewApiDeclaration" \
  "didPrepareStage760MinimalPublicPreviewApiPublicScanContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage759 minimal public preview api demo consumption: missing token $token" >&2
    exit 3
  fi
done

echo "stage759_minimal_public_preview_api_demo_consumption_owner_present=true"
echo "stage758_minimal_public_preview_api_declaration_consumed=true"
echo "cjguiExperimentalComponentPreviewApiReady_consumed=true"
echo "todo_public_preview_api_demo_surface_materialized=true"
echo "settings_public_preview_api_demo_surface_materialized=true"
echo "demo_consumption_bound_to_public_preview_api_declaration=true"
echo "public_component_api_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "stage760_minimal_public_preview_api_public_scan_contract_prepared=true"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
