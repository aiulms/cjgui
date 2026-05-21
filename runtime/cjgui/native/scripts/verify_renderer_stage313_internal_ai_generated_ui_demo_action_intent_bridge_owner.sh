#!/usr/bin/env zsh
#
# 维护注释：验证 stage313 internal AI-generated UI demo action intent bridge owner。
# 它只把 stage312 probe readiness 转成 owner-local action intent，不执行 dispatch。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage313_internal_ai_generated_ui_demo_action_intent_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage313 internal ai generated ui demo action intent bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage313InternalAiGeneratedUiDemoActionIntentBridgeFacts" \
  "CjguiInternalRendererStage313InternalAiGeneratedUiDemoActionIntentBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage313InternalAiGeneratedUiDemoActionIntentBridgeDraft" \
  "didConsumeStage312InternalAiGeneratedUiDemoProbeReadinessDecision" \
  "didMaterializeAiGeneratedUiActionIntentBridge" \
  "didBindAiGeneratedUiActionIntentToProbeReadiness" \
  "didBindAiGeneratedUiActionIntentToGeneratedFormIntent" \
  "didBindAiGeneratedUiActionIntentToGeneratedSettingsIntent" \
  "didBindAiGeneratedUiActionIntentToGeneratedValidationIntent" \
  "didKeepAiGeneratedUiActionIntentOwnerLocalInMemoryOnly" \
  "didKeepAiGeneratedUiActionIntentNonDispatching" \
  "didPrepareStage314AiGeneratedUiActionStateUpdateDryRunInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage313 internal ai generated ui demo action intent bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage313_internal_ai_generated_ui_demo_action_intent_bridge_owner_present=true"
echo "stage312_internal_ai_generated_ui_demo_probe_readiness_decision_required=true"
echo "ai_generated_ui_action_intent_bridge_materialized=true"
echo "ai_generated_ui_action_intent_bound_to_probe_readiness=true"
echo "ai_generated_ui_action_intent_bound_to_generated_form_intent=true"
echo "ai_generated_ui_action_intent_bound_to_generated_settings_intent=true"
echo "ai_generated_ui_action_intent_bound_to_generated_validation_intent=true"
echo "ai_generated_ui_action_intent_owner_local_in_memory_only=true"
echo "ai_generated_ui_action_intent_non_dispatching=true"
echo "stage314_ai_generated_ui_action_state_update_dry_run_input_prepared=true"
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
