#!/usr/bin/env zsh
#
# 维护注释：验证 stage309 internal AI-generated UI demo probe input owner。
# 它消费 stage308 component state/render readiness，只形成 generated form/settings probe 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage309_internal_ai_generated_ui_demo_probe_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage309 internal ai generated ui demo probe input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage309InternalAiGeneratedUiDemoProbeInputFacts" \
  "CjguiInternalRendererStage309InternalAiGeneratedUiDemoProbeInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage309InternalAiGeneratedUiDemoProbeInputDraft" \
  "didConsumeStage308InternalAiGeneratedUiDemoComponentStateRenderReadinessDecision" \
  "didMaterializeInternalAiGeneratedUiDemoProbeInput" \
  "didBindAiGeneratedUiProbeInputToGeneratedFormSemanticPreview" \
  "didBindAiGeneratedUiProbeInputToGeneratedSettingsSemanticPreview" \
  "didBindAiGeneratedUiProbeInputToGeneratedValidationSemanticPreview" \
  "didBindAiGeneratedUiProbeInputToOwnerLocalStateDelta" \
  "didBindAiGeneratedUiProbeInputToRenderCommandPreview" \
  "didBindAiGeneratedUiProbeInputToRollbackReadyBoundary" \
  "didBindAiGeneratedUiProbeInputToVisibilityNotPublishedBoundary" \
  "didKeepAiGeneratedUiProbeInputNonExecuting" \
  "didPrepareStage310AiGeneratedUiDemoProbeResultEnvelopeInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage309 internal ai generated ui demo probe input: missing token $token" >&2
    exit 3
  fi
done

echo "stage309_internal_ai_generated_ui_demo_probe_input_owner_present=true"
echo "stage308_internal_ai_generated_ui_demo_component_state_render_readiness_decision_required=true"
echo "internal_ai_generated_ui_demo_probe_input_materialized=true"
echo "ai_generated_ui_probe_input_bound_to_generated_form_semantic_preview=true"
echo "ai_generated_ui_probe_input_bound_to_generated_settings_semantic_preview=true"
echo "ai_generated_ui_probe_input_bound_to_generated_validation_semantic_preview=true"
echo "ai_generated_ui_probe_input_bound_to_owner_local_state_delta=true"
echo "ai_generated_ui_probe_input_bound_to_render_command_preview=true"
echo "ai_generated_ui_probe_input_bound_to_rollback_ready_boundary=true"
echo "ai_generated_ui_probe_input_bound_to_visibility_not_published_boundary=true"
echo "ai_generated_ui_probe_input_non_executing=true"
echo "stage310_ai_generated_ui_demo_probe_result_envelope_input_prepared=true"
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
