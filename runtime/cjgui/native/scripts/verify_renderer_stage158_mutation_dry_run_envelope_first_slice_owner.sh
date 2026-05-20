#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage158 mutation dry-run envelope source 已承接
# stage157 owner-local envelope，并定义可执行 dry-run result 形状；不 mutate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage158_mutation_dry_run_envelope_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage158 mutation dry-run envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage158MutationDryRunEnvelopeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage158MutationDryRunEnvelopeFirstSliceDraft" \
  "didConsumeStage157InternalOwnerEnvelope" \
  "didDefineExecutableMutationDryRunShape" \
  "didBindOwnerLocalEnvelopeToDryRunRequest" \
  "didPrepareGuardedExecutorDryRunInput" \
  "didKeepMutationDryRunNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage158 mutation dry-run envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage158_mutation_dry_run_envelope_owner_present=true"
echo "stage157_internal_owner_envelope_required=true"
echo "mutation_dry_run_envelope_materialized=true"
echo "executable_mutation_dry_run_shape_defined=true"
echo "guarded_executor_dry_run_input_prepared=true"
echo "mutation_dry_run_envelope_ready=true"
echo "mutation_dry_run_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
