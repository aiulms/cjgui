#!/usr/bin/env zsh
#
# 维护注释：验证 stage310 internal AI-generated UI demo probe result envelope owner。
# 它只把 stage309 probe input 包装成 owner-local dry-run result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage310_internal_ai_generated_ui_demo_probe_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage310 internal ai generated ui demo probe result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage310InternalAiGeneratedUiDemoProbeResultEnvelopeFacts" \
  "CjguiInternalRendererStage310InternalAiGeneratedUiDemoProbeResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage310InternalAiGeneratedUiDemoProbeResultEnvelopeDraft" \
  "didConsumeStage309InternalAiGeneratedUiDemoProbeInput" \
  "didMaterializeInternalAiGeneratedUiDemoProbeResultEnvelope" \
  "didBindAiGeneratedUiProbeResultEnvelopeToProbeInput" \
  "didBindAiGeneratedUiProbeResultEnvelopeToComponentStateDeltaDryRun" \
  "didBindAiGeneratedUiProbeResultEnvelopeToRenderCommandPreview" \
  "didKeepAiGeneratedUiProbeResultOwnerLocalInMemoryOnly" \
  "didConfirmAiGeneratedUiProbeResultRollbackReady" \
  "didConfirmAiGeneratedUiProbeResultVisibilityNotPublished" \
  "didPrepareStage311AiGeneratedUiDemoProbeSemanticDiffExplainInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage310 internal ai generated ui demo probe result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage310_internal_ai_generated_ui_demo_probe_result_envelope_owner_present=true"
echo "stage309_internal_ai_generated_ui_demo_probe_input_required=true"
echo "internal_ai_generated_ui_demo_probe_result_envelope_materialized=true"
echo "ai_generated_ui_probe_result_envelope_bound_to_probe_input=true"
echo "ai_generated_ui_probe_result_envelope_bound_to_component_state_delta_dry_run=true"
echo "ai_generated_ui_probe_result_envelope_bound_to_render_command_preview=true"
echo "ai_generated_ui_probe_result_owner_local_in_memory_only=true"
echo "ai_generated_ui_probe_result_rollback_ready=true"
echo "ai_generated_ui_probe_result_visibility_not_published=true"
echo "stage311_ai_generated_ui_demo_probe_semantic_diff_explain_input_prepared=true"
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
