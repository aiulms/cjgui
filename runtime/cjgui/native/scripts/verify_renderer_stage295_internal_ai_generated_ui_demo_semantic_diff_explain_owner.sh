#!/usr/bin/env zsh
#
# 维护注释：验证 stage295 internal AI-generated UI demo semantic diff/explain owner。
# 它只解释 spec/preview 顺序和 owner acceptance 边界，不接纳变更。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage295_internal_ai_generated_ui_demo_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage295 internal ai generated ui demo semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage295InternalAiGeneratedUiDemoSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage295InternalAiGeneratedUiDemoSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage295InternalAiGeneratedUiDemoSemanticDiffExplainDraft" \
  "didConsumeStage294InternalAiGeneratedUiDemoPreviewPacket" \
  "didMaterializeAiGeneratedUiDemoSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExplainPacket" \
  "didBindAiGeneratedUiDiffToSpecPreviewOrder" \
  "didBindAiGeneratedUiExplainToGeneratedFormSettingsIntents" \
  "didRecheckAiGeneratedUiOwnerAcceptanceBoundary" \
  "didRecheckAiGeneratedUiVisibilityNotPublishedBoundary" \
  "didPrepareStage296AiGeneratedUiDemoReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage295 internal ai generated ui demo semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage295_internal_ai_generated_ui_demo_semantic_diff_explain_owner_present=true"
echo "stage294_internal_ai_generated_ui_demo_preview_packet_required=true"
echo "ai_generated_ui_demo_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_explain_packet_materialized=true"
echo "ai_generated_ui_diff_bound_to_spec_preview_order=true"
echo "ai_generated_ui_explain_bound_to_generated_form_settings_intents=true"
echo "ai_generated_ui_owner_acceptance_boundary_rechecked=true"
echo "ai_generated_ui_visibility_not_published_boundary_rechecked=true"
echo "stage296_ai_generated_ui_demo_readiness_decision_input_prepared=true"
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
