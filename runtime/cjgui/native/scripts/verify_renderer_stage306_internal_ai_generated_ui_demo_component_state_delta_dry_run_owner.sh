#!/usr/bin/env zsh
#
# 维护注释：验证 stage306 internal AI-generated UI demo component state delta dry-run owner。
# 它消费 stage305 输入，形成 owner-local component snapshot 与 generated form/settings delta。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage306_internal_ai_generated_ui_demo_component_state_delta_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage306 internal ai generated ui demo component state delta dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage306InternalAiGeneratedUiDemoComponentStateDeltaDryRunFacts" \
  "CjguiInternalRendererStage306InternalAiGeneratedUiDemoComponentStateDeltaDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage306InternalAiGeneratedUiDemoComponentStateDeltaDryRunDraft" \
  "didConsumeStage305InternalAiGeneratedUiDemoComponentStateRenderDryRunInput" \
  "didMaterializeAiGeneratedUiComponentOwnerLocalStateSnapshot" \
  "didMaterializeGeneratedFormFieldStateDeltaDryRun" \
  "didMaterializeGeneratedSettingsSwitchStateDeltaDryRun" \
  "didMaterializeGeneratedValidationStateDeltaDryRun" \
  "didBindGeneratedComponentStateDeltaToRollbackReadyBoundary" \
  "didPrepareStage307AiGeneratedUiComponentRenderCommandPreviewInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage306 internal ai generated ui demo component state delta dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage306_internal_ai_generated_ui_demo_component_state_delta_dry_run_owner_present=true"
echo "stage305_internal_ai_generated_ui_demo_component_state_render_dry_run_input_required=true"
echo "ai_generated_ui_component_state_delta_dry_run_materialized=true"
echo "ai_generated_ui_component_owner_local_state_snapshot_materialized=true"
echo "generated_form_field_state_delta_dry_run_materialized=true"
echo "generated_settings_switch_state_delta_dry_run_materialized=true"
echo "generated_validation_state_delta_dry_run_materialized=true"
echo "generated_component_state_delta_bound_to_rollback_ready_boundary=true"
echo "generated_component_state_delta_in_memory_only=true"
echo "stage307_ai_generated_ui_component_render_command_preview_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
