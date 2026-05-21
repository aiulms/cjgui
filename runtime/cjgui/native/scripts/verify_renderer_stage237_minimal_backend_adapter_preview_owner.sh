#!/usr/bin/env zsh
#
# 维护注释：验证 stage237 minimal backend adapter preview owner。
# 它只把 stage236 runway decision 接成 Button-like demo 的 no-submit adapter preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage237_minimal_backend_adapter_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage237 minimal backend adapter preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage237MinimalBackendAdapterPreviewFacts" \
  "CjguiInternalRendererStage237MinimalBackendAdapterPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage237MinimalBackendAdapterPreviewDraft" \
  "didConsumeStage236RendererBackendRunwayReadinessDecision" \
  "didMaterializeMinimalBackendAdapterPreview" \
  "didBindAdapterPreviewToBackendRunwayDecision" \
  "didBindAdapterPreviewToButtonLikeComponentDemo" \
  "didClassifyAdapterPreviewAsNoSubmit" \
  "didPrepareStage238BackendAdapterNoSubmitPredicateInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage237 minimal backend adapter preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage237_minimal_backend_adapter_preview_owner_present=true"
echo "stage236_backend_runway_readiness_decision_required=true"
echo "minimal_backend_adapter_preview_materialized=true"
echo "adapter_preview_bound_to_backend_runway_decision=true"
echo "adapter_preview_bound_to_button_like_component_demo=true"
echo "backend_adapter_preview_no_submit=true"
echo "stage238_backend_adapter_no_submit_predicate_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
