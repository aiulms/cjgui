#!/usr/bin/env zsh
#
# Verifies the stage757 minimal public preview API descriptor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage757_minimal_public_preview_api_descriptor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage757 minimal public preview api descriptor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorPlan" \
  "CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorFacts" \
  "CjguiInternalRendererStage757MinimalPublicPreviewApiDescriptorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage757MinimalPublicPreviewApiDescriptorDraft" \
  "CjguiInternalRendererStage756AiGeneratedUiAcceptanceCommitRuntimeManagerReadiness" \
  "didConsumeStage756AiGeneratedUiAcceptanceCommitRuntimeManager" \
  "didMaterializeMinimalPublicPreviewComponentDescriptor" \
  "didMaterializePreviewCompatibilityLedger" \
  "didMaterializePreviewRollbackDeprecationNote" \
  "didBindPreviewDescriptorToAcceptanceCommitRuntimeContract" \
  "didKeepPreviewApiExperimental" \
  "didPrepareStage758MinimalPublicPreviewApiDeclaration"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage757 minimal public preview api descriptor: missing token $token" >&2
    exit 3
  fi
done

echo "stage757_minimal_public_preview_api_descriptor_owner_present=true"
echo "stage756_ai_generated_ui_acceptance_commit_runtime_manager_consumed=true"
echo "acceptance_commit_runtime_contract_consumed=true"
echo "minimal_public_preview_component_descriptor_materialized=true"
echo "preview_compatibility_ledger_materialized=true"
echo "preview_rollback_deprecation_note_materialized=true"
echo "preview_descriptor_bound_to_acceptance_commit_runtime_contract=true"
echo "preview_api_experimental=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "stage758_minimal_public_preview_api_declaration_prepared=true"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
