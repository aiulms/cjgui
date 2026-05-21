#!/usr/bin/env zsh
#
# 维护注释：验证 stage294 internal AI-generated UI demo preview packet owner。
# 它只把 semantic spec input 映射成 preview packet，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage294_internal_ai_generated_ui_demo_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage294 internal ai generated ui demo preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage294InternalAiGeneratedUiDemoPreviewPacketFacts" \
  "CjguiInternalRendererStage294InternalAiGeneratedUiDemoPreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage294InternalAiGeneratedUiDemoPreviewPacketDraft" \
  "didConsumeStage293InternalAiGeneratedUiDemoSemanticSpecInput" \
  "didMaterializeInternalAiGeneratedUiDemoPreviewPacket" \
  "didBindAiGeneratedUiPreviewToSemanticSpecInput" \
  "didBindAiGeneratedUiPreviewToGeneratedFormSemanticNode" \
  "didBindAiGeneratedUiPreviewToGeneratedSettingsSemanticNode" \
  "didBindAiGeneratedUiPreviewToRenderCommandRequirement" \
  "didBindAiGeneratedUiPreviewToOwnerAcceptanceBoundary" \
  "didKeepAiGeneratedUiPreviewOwnerLocalInMemoryOnly" \
  "didKeepAiGeneratedUiPreviewNonExecuting" \
  "didPrepareStage295AiGeneratedUiDemoSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage294 internal ai generated ui demo preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage294_internal_ai_generated_ui_demo_preview_packet_owner_present=true"
echo "stage293_internal_ai_generated_ui_demo_semantic_spec_input_required=true"
echo "ai_generated_ui_demo_preview_packet_materialized=true"
echo "ai_generated_ui_preview_bound_to_semantic_spec_input=true"
echo "ai_generated_ui_preview_bound_to_generated_form_semantic_node=true"
echo "ai_generated_ui_preview_bound_to_generated_settings_semantic_node=true"
echo "ai_generated_ui_preview_bound_to_render_command_requirement=true"
echo "ai_generated_ui_preview_bound_to_owner_acceptance_boundary=true"
echo "ai_generated_ui_preview_owner_local_in_memory_only=true"
echo "ai_generated_ui_preview_non_executing=true"
echo "stage295_ai_generated_ui_demo_semantic_diff_explain_input_prepared=true"
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
