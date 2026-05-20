#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage134 visible-order smoke first-slice owner。
# Truth: 只检查 runtime internal owner 的符号、stage133 输入与停止线。
# Stop-line: owner 不直接触发 AppKit visible order，不获取 drawable，不创建
# Metal/encoder/draw/commit/present，不写 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice.cj"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage134 visible order smoke owner: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceReadiness"
  "didRequireFreshBoundedVisibleOrderSmokeProbe"
  "didMaterializeNsApplicationWindowViewVisibleOrder"
  "didRequireAutoCloseCleanupBeforeDrawableRoute"
  "didPrepareDrawableReadinessReprobeRoute"
  "didConfirmNoMetalDrawableEncoderDrawCommitPresent"
  "didConfirmNoRendererStateWrite"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage134 visible order smoke owner: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke owner: forbidden public or FFI surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|presentDrawable|commit\]|MTLDevice|CAMetalLayer|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*' >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke owner: forbidden native/render token found" >&2
  exit 6
fi

if git -C "$ROOT_DIR/../.." diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui stage134 visible order smoke owner: protected path modified" >&2
  exit 7
fi

echo "cjgui stage134 visible order smoke owner: owner_file=$OWNER_FILE"
echo "cjgui stage134 visible order smoke owner: runtime_owner_present=true"
echo "cjgui stage134 visible order smoke owner: upstream_stage133_state_token_gate=true"
echo "cjgui stage134 visible order smoke owner: bounded_visible_order_smoke_probe_required=true"
echo "cjgui stage134 visible order smoke owner: drawable_readiness_reprobe_route_prepared=true"
echo "cjgui stage134 visible order smoke owner: renderer_state_write=false"
echo "cjgui stage134 visible order smoke owner: runtime_state_write=false"
