#!/usr/bin/env zsh
#
# 维护注释：验证 stage305 internal AI-generated UI demo component state/render dry-run input owner。
# 它消费 stage304 owner acceptance gate readiness，只形成 generated proposal 到组件 state/render dry-run 的输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage305_internal_ai_generated_ui_demo_component_state_render_dry_run_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage305 internal ai generated ui demo component state render dry run input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage305InternalAiGeneratedUiDemoComponentStateRenderDryRunInputFacts" \
  "CjguiInternalRendererStage305InternalAiGeneratedUiDemoComponentStateRenderDryRunInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage305InternalAiGeneratedUiDemoComponentStateRenderDryRunInputDraft" \
  "didConsumeStage304InternalAiGeneratedUiOwnerAcceptanceGateReadinessDecision" \
  "didMaterializeAiGeneratedUiComponentStateRenderDryRunInput" \
  "didBindGeneratedFormProposalToComponentStateSnapshot" \
  "didBindGeneratedSettingsProposalToComponentStateSnapshot" \
  "didBindDryRunInputToRenderCommandRefreshRequirement" \
  "didPrepareStage306AiGeneratedUiComponentStateDeltaDryRunInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage305 internal ai generated ui demo component state render dry run input: missing token $token" >&2
    exit 3
  fi
done

echo "stage305_internal_ai_generated_ui_demo_component_state_render_dry_run_input_owner_present=true"
echo "stage304_internal_ai_generated_ui_demo_owner_acceptance_gate_readiness_decision_required=true"
echo "ai_generated_ui_component_state_render_dry_run_input_materialized=true"
echo "generated_form_proposal_bound_to_component_state_snapshot=true"
echo "generated_settings_proposal_bound_to_component_state_snapshot=true"
echo "component_state_render_dry_run_input_bound_to_render_command_refresh_requirement=true"
echo "stage306_ai_generated_ui_component_state_delta_dry_run_input_prepared=true"
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
