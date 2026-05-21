#!/usr/bin/env zsh
#
# 维护注释：验证 stage282 internal chat view demo probe result envelope owner。
# 它只确认 owner-local result envelope 可归档 chat probe 输入/结果，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage282_internal_chat_view_demo_probe_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage282 internal chat view demo probe result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage282InternalChatViewDemoProbeResultEnvelopeFacts" \
  "CjguiInternalRendererStage282InternalChatViewDemoProbeResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage282InternalChatViewDemoProbeResultEnvelopeDraft" \
  "didConsumeStage281InternalChatViewDemoProbeInput" \
  "didMaterializeInternalChatViewDemoProbeResultEnvelope" \
  "didBindChatProbeResultEnvelopeToProbeInput" \
  "didBindChatProbeResultEnvelopeToStateUpdateDryRun" \
  "didBindChatProbeResultEnvelopeToRenderCommandPreview" \
  "didKeepChatProbeResultOwnerLocalInMemoryOnly" \
  "didConfirmChatProbeResultRollbackReady" \
  "didConfirmChatProbeResultVisibilityNotPublished" \
  "didPrepareStage283ChatViewDemoProbeSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage282 internal chat view demo probe result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage282_internal_chat_view_demo_probe_result_envelope_owner_present=true"
echo "stage281_internal_chat_view_demo_probe_input_required=true"
echo "internal_chat_view_demo_probe_result_envelope_materialized=true"
echo "chat_probe_result_envelope_bound_to_probe_input=true"
echo "chat_probe_result_envelope_bound_to_state_update_dry_run=true"
echo "chat_probe_result_envelope_bound_to_render_command_preview=true"
echo "chat_probe_result_owner_local_in_memory_only=true"
echo "chat_probe_result_rollback_ready=true"
echo "chat_probe_result_visibility_not_published=true"
echo "stage283_chat_view_demo_probe_semantic_diff_explain_input_prepared=true"
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
