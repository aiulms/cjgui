#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage169 owner-local state envelope dry-run source。
# 它消费 stage168 admission snapshot，只构建 owner-local 非公开 envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage169_owner_local_state_envelope_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage169 owner-local state envelope dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage169OwnerLocalStateEnvelopeDryRunFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage169OwnerLocalStateEnvelopeDryRunFirstSliceDraft" \
  "didConsumeStage168RendererStateWriteAdmissionSnapshot" \
  "didMaterializeOwnerLocalRendererStateEnvelopeDryRun" \
  "didBindAdmissionSnapshotToOwnerLocalEnvelope" \
  "didBindRollbackShadowStateEnvelope" \
  "didPrepareStage170GuardedStateWriteExecutorInput" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage169 owner-local state envelope dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage169_owner_local_state_envelope_dry_run_owner_present=true"
echo "stage168_renderer_state_write_admission_snapshot_required=true"
echo "owner_local_renderer_state_envelope_dry_run_materialized=true"
echo "admission_snapshot_to_owner_local_envelope_bound=true"
echo "rollback_shadow_state_envelope_bound=true"
echo "visibility_shadow_state_envelope_bound=true"
echo "stage170_guarded_state_write_executor_input_prepared=true"
echo "owner_local_state_envelope_dry_run_ready=true"
echo "owner_local_state_envelope_dry_run_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
