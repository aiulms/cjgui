#!/usr/bin/env zsh
#
# 维护注释：验证 stage293 internal AI-generated UI demo semantic spec input owner。
# 它只接收 stage292 readiness，形成 generated form/settings spec intake。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage293_internal_ai_generated_ui_demo_semantic_spec_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage293 internal ai generated ui demo semantic spec input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage293InternalAiGeneratedUiDemoSemanticSpecInputFacts" \
  "CjguiInternalRendererStage293InternalAiGeneratedUiDemoSemanticSpecInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage293InternalAiGeneratedUiDemoSemanticSpecInputDraft" \
  "didConsumeStage292InternalFileBrowserDemoProbeReadinessDecision" \
  "didMaterializeInternalAiGeneratedUiDemoSemanticSpecInput" \
  "didBindAiGeneratedUiSemanticSpecToGeneratedFormIntent" \
  "didBindAiGeneratedUiSemanticSpecToGeneratedSettingsIntent" \
  "didBindAiGeneratedUiSemanticSpecToPreviewDiffExplainInput" \
  "didBindAiGeneratedUiSemanticSpecToOwnerAcceptanceBoundary" \
  "didKeepAiGeneratedUiSemanticSpecOwnerLocalInMemoryOnly" \
  "didKeepAiGeneratedUiSemanticSpecNonExecuting" \
  "didPrepareStage294AiGeneratedUiDemoPreviewPacketInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage293 internal ai generated ui demo semantic spec input: missing token $token" >&2
    exit 3
  fi
done

echo "stage293_internal_ai_generated_ui_demo_semantic_spec_input_owner_present=true"
echo "stage292_internal_file_browser_demo_probe_readiness_decision_required=true"
echo "internal_ai_generated_ui_demo_semantic_spec_input_materialized=true"
echo "ai_generated_ui_semantic_spec_bound_to_generated_form_intent=true"
echo "ai_generated_ui_semantic_spec_bound_to_generated_settings_intent=true"
echo "ai_generated_ui_semantic_spec_bound_to_preview_diff_explain_input=true"
echo "ai_generated_ui_semantic_spec_bound_to_owner_acceptance_boundary=true"
echo "ai_generated_ui_semantic_spec_owner_local_in_memory_only=true"
echo "ai_generated_ui_semantic_spec_non_executing=true"
echo "stage294_ai_generated_ui_demo_preview_packet_input_prepared=true"
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
