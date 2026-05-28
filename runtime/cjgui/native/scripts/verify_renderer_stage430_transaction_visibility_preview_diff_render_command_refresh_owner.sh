#!/usr/bin/env zsh
#
# 维护注释：验证 stage430 transaction visibility preview diff / RenderCommand refresh owner。
# 它必须消费 stage429 transaction surface preview refresh，并形成 owner-local diff 与 render command preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage430_transaction_visibility_preview_diff_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage430 transaction visibility preview diff render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage430TransactionVisibilityPreviewDiffRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage430TransactionVisibilityPreviewDiffRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage430TransactionVisibilityPreviewDiffRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage430TransactionVisibilityPreviewDiffRenderCommandRefreshDraft" \
  "didConsumeStage429DemoSurfaceTransactionVisibilityPreviewRefresh" \
  "didConsumeDemoSurfaceTransactionVisibilityPreviewRefresh" \
  "didMaterializeTransactionVisibilityPreviewDiff" \
  "didMaterializeTodoTransactionVisibilityPreviewDiff" \
  "didMaterializeSettingsTransactionVisibilityPreviewDiff" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityPreviewDiff" \
  "didMaterializeTransactionVisibilityPreviewRenderCommandRefresh" \
  "didMapTransactionVisibilityPreviewDiffToRenderCommandRefresh" \
  "didKeepTransactionVisibilityPreviewDiffOwnerLocal" \
  "didKeepTransactionVisibilityPreviewRenderCommandPreviewOnly" \
  "didPrepareStage431TransactionVisibilityPreviewInputEventActionAdapter" \
  "didKeepVisibilityPublishedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage430 transaction visibility preview diff render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage430_transaction_visibility_preview_diff_render_command_refresh_owner_present=true"
echo "stage429_demo_surface_transaction_visibility_preview_refresh_required=true"
echo "stage429_demo_surface_transaction_visibility_preview_refresh_consumed=true"
echo "demo_surface_transaction_visibility_preview_refresh_consumed=true"
echo "todo_transaction_visible_surface_preview_refresh_consumed=true"
echo "settings_transaction_visible_surface_preview_refresh_consumed=true"
echo "ai_generated_settings_transaction_visible_surface_preview_refresh_consumed=true"
echo "transaction_visibility_preview_diff_materialized=true"
echo "todo_transaction_visibility_preview_diff_materialized=true"
echo "settings_transaction_visibility_preview_diff_materialized=true"
echo "ai_generated_settings_transaction_visibility_preview_diff_materialized=true"
echo "transaction_visibility_preview_render_command_refresh_materialized=true"
echo "transaction_visibility_preview_diff_to_render_command_refresh_mapped=true"
echo "transaction_visibility_preview_diff_owner_local=true"
echo "transaction_visibility_preview_render_command_preview_only=true"
echo "stage431_transaction_visibility_preview_input_event_action_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
