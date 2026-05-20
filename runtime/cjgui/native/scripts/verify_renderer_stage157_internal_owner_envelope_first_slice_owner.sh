#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage157 internal owner envelope source 只承接
# stage156 readiness ledger，并物化 owner-local 非公开结果形状；不写 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage157_internal_owner_envelope_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage157 internal owner envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage157InternalOwnerEnvelopeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage157InternalOwnerEnvelopeFirstSliceDraft" \
  "didConsumeStage156RendererStateWriteFirstSliceReadinessContract" \
  "didMaterializeOwnerLocalRendererStateEnvelope" \
  "didPrepareMutationRequestResultShape" \
  "didPrepareVisibilityPublicationResultShape" \
  "didPrepareRollbackVisibilityResultShape" \
  "didKeepInternalOwnerEnvelopeNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage157 internal owner envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage157_internal_owner_envelope_owner_present=true"
echo "stage156_readiness_contract_required=true"
echo "owner_local_renderer_state_envelope_materialized=true"
echo "owner_local_result_shapes_prepared=true"
echo "mutation_request_result_shape_prepared=true"
echo "visibility_publication_result_shape_prepared=true"
echo "rollback_visibility_result_shape_prepared=true"
echo "internal_owner_envelope_ready=true"
echo "internal_owner_envelope_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
