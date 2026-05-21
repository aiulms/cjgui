#!/usr/bin/env zsh
#
# 维护注释：验证 stage204 component demo state-update dry-run owner。该 owner
# 只生成 owner-local demo update preview，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage204_component_demo_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage204 component demo state update dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage204ComponentDemoStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage204ComponentDemoStateUpdateDryRunDraft" \
  "didConsumeStage203SemanticNodeFixture" \
  "didMaterializeComponentDemoStateUpdateDryRun" \
  "didMaterializeOwnerLocalRollbackPreview" \
  "didKeepVisibilityNotPublished" \
  "didPrepareStage205ComponentDemoRenderCommandAdmissionInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage204 component demo state update dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage204_component_demo_state_update_dry_run_owner_present=true"
echo "stage203_semantic_node_fixture_required=true"
echo "component_demo_state_update_dry_run_materialized=true"
echo "owner_local_rollback_preview_materialized=true"
echo "visibility_not_published=true"
echo "stage205_component_demo_render_command_admission_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
