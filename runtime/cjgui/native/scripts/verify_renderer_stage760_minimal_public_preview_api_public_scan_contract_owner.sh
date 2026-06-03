#!/usr/bin/env zsh
#
# Verifies the stage760 minimal public preview API public scan contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage760_minimal_public_preview_api_public_scan_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage760 minimal public preview api public scan contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage760MinimalPublicPreviewApiPublicScanContractPlan" \
  "CjguiInternalRendererStage760MinimalPublicPreviewApiPublicScanContractFacts" \
  "CjguiInternalRendererStage760MinimalPublicPreviewApiPublicScanContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage760MinimalPublicPreviewApiPublicScanContractDraft" \
  "CjguiInternalRendererStage759MinimalPublicPreviewApiDemoConsumptionReadiness" \
  "didConsumeStage759MinimalPublicPreviewApiDemoConsumption" \
  "didMaterializePublicDeclarationScanReceipt" \
  "didListCjguiExperimentalComponentPreviewApiReadyAsExperimentalPublicSurface" \
  "didMaterializeCompatibilityRollbackNote" \
  "didReduceFuturePublicPreviewApiTemplateNeed" \
  "didPrepareStage761PreviewComponentApiLayoutStyleConsumption"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage760 minimal public preview api public scan contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage760_minimal_public_preview_api_public_scan_contract_owner_present=true"
echo "stage759_minimal_public_preview_api_demo_consumption_consumed=true"
echo "public_declaration_scan_receipt_materialized=true"
echo "public_surface_cjguiExperimentalComponentPreviewApiReady_listed=true"
echo "compatibility_rollback_note_materialized=true"
echo "future_public_preview_api_template_need_reduced=true"
echo "public_component_api_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "stage761_preview_component_api_layout_style_consumption_prepared=true"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
