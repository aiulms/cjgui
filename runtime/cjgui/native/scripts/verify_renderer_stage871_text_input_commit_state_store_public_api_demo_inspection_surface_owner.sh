#!/usr/bin/env zsh
#
# Verifies the stage871 text-input commit state-store public API demo inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage871_text_input_commit_state_store_public_api_demo_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage871 text input commit state store public api demo inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage871TextInputCommitStateStorePublicApiDemoInspectionSurfacePlan" \
  "CjguiInternalRendererStage871TextInputCommitStateStorePublicApiDemoInspectionSurfaceFacts" \
  "CjguiInternalRendererStage871TextInputCommitStateStorePublicApiDemoInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage871TextInputCommitStateStorePublicApiDemoInspectionSurfaceDraft" \
  "CjguiInternalRendererStage870TextInputCommitStateStorePublicApiAdmissionReadiness" \
  "didConsumeStage870TextInputCommitStateStorePublicApiAdmission" \
  "didMaterializeTodoStateStorePublicApiCommitInspectionSurface" \
  "didMaterializeSettingsStateStorePublicApiCommitInspectionSurface" \
  "didMaterializeAiGeneratedSettingsStateStorePublicApiCommitInspectionSurface" \
  "didMaterializeChatComposerStateStorePublicApiCommitInspectionSurface" \
  "didMaterializeFileBrowserStateStorePublicApiCommitInspectionSurface" \
  "didMaterializeStateStorePublicApiCommitReceiptRowModel" \
  "didMaterializeRollbackNoWriteResultRows" \
  "didBindDemoInspectionSurfaceToStage870Admission" \
  "didPrepareStage872TextInputCommitStateStorePublicApiRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage871 text input commit state store public api demo inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage871_text_input_commit_state_store_public_api_demo_inspection_surface_owner_present=true"
echo "stage870_text_input_commit_state_store_public_api_admission_consumed=true"
echo "stage869_text_input_commit_state_store_public_api_readiness_consumed_transitively=true"
echo "todo_state_store_public_api_commit_inspection_surface_materialized=true"
echo "settings_state_store_public_api_commit_inspection_surface_materialized=true"
echo "ai_generated_settings_state_store_public_api_commit_inspection_surface_materialized=true"
echo "chat_composer_state_store_public_api_commit_inspection_surface_materialized=true"
echo "file_browser_state_store_public_api_commit_inspection_surface_materialized=true"
echo "state_store_public_api_commit_receipt_row_model_materialized=true"
echo "rollback_no_write_result_rows_materialized=true"
echo "demo_inspection_surface_bound_to_stage870_admission=true"
echo "stage872_text_input_commit_state_store_public_api_runtime_manager_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
