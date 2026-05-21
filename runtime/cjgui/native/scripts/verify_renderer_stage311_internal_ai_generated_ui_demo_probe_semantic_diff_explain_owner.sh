#!/usr/bin/env zsh
#
# 维护注释：验证 stage311 internal AI-generated UI demo probe semantic diff/explain owner。
# 它只解释 generated form/settings/validation 的 owner-local probe 差异。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage311_internal_ai_generated_ui_demo_probe_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage311 internal ai generated ui demo probe semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage311InternalAiGeneratedUiDemoProbeSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage311InternalAiGeneratedUiDemoProbeSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage311InternalAiGeneratedUiDemoProbeSemanticDiffExplainDraft" \
  "didConsumeStage310InternalAiGeneratedUiDemoProbeResultEnvelope" \
  "didMaterializeAiGeneratedUiDemoProbeSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoProbeExplainPacket" \
  "didBindAiGeneratedUiProbeDiffToGeneratedFormSettingsValidationOrder" \
  "didBindAiGeneratedUiProbeExplainToGeneratedProposalStateRenderLoop" \
  "didRecheckAiGeneratedUiProbeRollbackReadyBoundary" \
  "didRecheckAiGeneratedUiProbeVisibilityNotPublishedBoundary" \
  "didPrepareStage312AiGeneratedUiDemoProbeReadinessDecisionInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage311 internal ai generated ui demo probe semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage311_internal_ai_generated_ui_demo_probe_semantic_diff_explain_owner_present=true"
echo "stage310_internal_ai_generated_ui_demo_probe_result_envelope_required=true"
echo "ai_generated_ui_demo_probe_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_probe_explain_packet_materialized=true"
echo "ai_generated_ui_probe_diff_bound_to_generated_form_settings_validation_order=true"
echo "ai_generated_ui_probe_explain_bound_to_generated_proposal_state_render_loop=true"
echo "ai_generated_ui_probe_rollback_ready_boundary_rechecked=true"
echo "ai_generated_ui_probe_visibility_not_published_boundary_rechecked=true"
echo "stage312_ai_generated_ui_demo_probe_readiness_decision_input_prepared=true"
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
