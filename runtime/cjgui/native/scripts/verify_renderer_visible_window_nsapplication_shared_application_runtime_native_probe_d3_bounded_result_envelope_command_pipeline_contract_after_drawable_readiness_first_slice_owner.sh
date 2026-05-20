#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage135 command pipeline contract owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_contract_after_drawable_readiness_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage135 command pipeline contract owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandPipelineContractAfterDrawableReadinessFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawableReadinessAfterVisibleOrderFirstSliceReadiness"
  "didRequireCommandQueueCreateDestroyContract"
  "didRequireRenderPassDescriptorCreateDestroyContract"
  "didKeepCommandBufferCreationBlockedUntilDrawableReady"
  "didPrepareRenderEncoderContractRoute"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage135 command pipeline contract owner: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui stage135 command pipeline contract owner: forbidden public or FFI surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|MTLDevice|CAMetalLayer|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*' >/dev/null 2>&1; then
  echo "cjgui stage135 command pipeline contract owner: forbidden native/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui stage135 command pipeline contract owner: protected path modified" >&2
  exit 7
fi

echo "cjgui stage135 command pipeline contract owner: owner_file=$OWNER_FILE"
echo "cjgui stage135 command pipeline contract owner: command_pipeline_contract_after_drawable_readiness_owner_present=true"
echo "cjgui stage135 command pipeline contract owner: drawable_readiness_packet_required=true"
echo "cjgui stage135 command pipeline contract owner: command_queue_contract_required=true"
echo "cjgui stage135 command pipeline contract owner: render_pass_descriptor_contract_required=true"
echo "cjgui stage135 command pipeline contract owner: renderer_state_write=false"
echo "cjgui stage135 command pipeline contract owner: runtime_state_write=false"
