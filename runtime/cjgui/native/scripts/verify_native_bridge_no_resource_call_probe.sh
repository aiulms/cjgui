#!/usr/bin/env zsh
#
# Owner: native bridge no-resource FFI call verification probe。
# Truth: 验证 runtime internal declaration owner、actual internal call owner source
# 与临时 package link probe 能观察 no-resource callable 返回事实。
# Stop-line: 不修改 runtime/cjgui/cjpm.toml，不接 public API，不调用 resource callable，不创建 native 对象。
# Same-shape Boundary Brake: no-resource call probe 只是 side-effect-free interop evidence，不是 backend-ready 或 runtime bridge permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
REPO_DIR="$(cd "$PACKAGE_DIR/../.." && pwd)"
DECLARATION_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj"
CALL_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_no_resource_call.cj"
MAIN_THREAD_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_main_thread_call.cj"
PACKAGE_LINK_PROBE="$SCRIPT_DIR/verify_native_bridge_cjpm_package_link_probe.sh"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-no-resource-call-XXXXXX)"
PROBE_LOG="$OUTPUT_DIR/cjpm-package-link-probe.log"
ALLOWED_SYMBOLS=(
  "cjgui_native_bridge_surface_version"
  "cjgui_native_bridge_surface_capabilities"
  "cjgui_native_bridge_status_ok"
  "cjgui_native_bridge_no_resource_admission"
)
MAIN_THREAD_SYMBOL="cjgui_native_bridge_is_main_thread"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge no-resource call probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$DECLARATION_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime declaration owner $DECLARATION_OWNER" >&2
  exit 3
fi

if [[ ! -f "$CALL_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime no-resource call owner $CALL_OWNER" >&2
  exit 3
fi

if [[ ! -f "$MAIN_THREAD_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime main-thread call owner $MAIN_THREAD_OWNER" >&2
  exit 3
fi

if [[ ! -f "$PACKAGE_LINK_PROBE" ]]; then
  echo "cjgui native bridge no-resource call probe: missing package link probe $PACKAGE_LINK_PROBE" >&2
  exit 4
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge no-resource call probe: missing production native skeleton" >&2
  exit 5
fi

for symbol in "${ALLOWED_SYMBOLS[@]}"; do
  if ! grep -E "foreign func ${symbol}\\(\\): UInt32" "$DECLARATION_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}()" "$CALL_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal owner call for $symbol" >&2
    exit 6
  fi
done

if ! grep -E "foreign func ${MAIN_THREAD_SYMBOL}\\(\\): Int32" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing internal foreign declaration for $MAIN_THREAD_SYMBOL" >&2
  exit 6
fi

if ! grep -F "${MAIN_THREAD_SYMBOL}()" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing internal owner call for $MAIN_THREAD_SYMBOL" >&2
  exit 6
fi

if ! grep -F "CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness" "$CALL_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing runtime call readiness endpoint" >&2
  exit 6
fi

if ! grep -F "cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft" "$CALL_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing runtime call default draft" >&2
  exit 6
fi

if ! grep -F "CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing main-thread call readiness endpoint" >&2
  exit 6
fi

if ! grep -F "cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing main-thread call default draft" >&2
  exit 6
fi

if grep -E 'cjgui_app_run|cjgui_last_error|NSWindow|NSView|CAMetalLayer|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release|destroy' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: production skeleton contains forbidden resource/native behavior token" >&2
  exit 7
fi

echo "cjgui native bridge no-resource call probe: requested=true"
echo "cjgui native bridge no-resource call probe: repo=$REPO_DIR"
echo "cjgui native bridge no-resource call probe: output=$OUTPUT_DIR"
echo "cjgui native bridge no-resource call probe: runtime_foreign_declarations_observed=true"
echo "cjgui native bridge no-resource call probe: runtime_adjacent_probe_route=true"
echo "cjgui native bridge no-resource call probe: runtime_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: main_thread_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: runtime_owner_call_executed_by_probe=false"

zsh "$PACKAGE_LINK_PROBE" | tee "$PROBE_LOG"

for observed_line in \
  "surface_version_observed=true" \
  "capabilities_observed=true" \
  "status_ok_observed=true" \
  "no_resource_admission_observed=true" \
  "main_thread_query_observed=true" \
  "main_thread_observed=true" \
  "success=true reason=none"; do
  if ! grep -F "$observed_line" "$PROBE_LOG" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing observed fact: $observed_line" >&2
    exit 8
  fi
done

echo "cjgui native bridge no-resource call probe: surface_version_observed=true"
echo "cjgui native bridge no-resource call probe: capabilities_observed=true"
echo "cjgui native bridge no-resource call probe: status_ok_observed=true"
echo "cjgui native bridge no-resource call probe: no_resource_admission_observed=true"
echo "cjgui native bridge no-resource call probe: main_thread_query_observed=true"
echo "cjgui native bridge no-resource call probe: main_thread_observed=true"
echo "cjgui native bridge no-resource call probe: runtime_package_config_modified=false"
echo "cjgui native bridge no-resource call probe: public_api_modified=false"
echo "cjgui native bridge no-resource call probe: resource_callable_invoked=false"
echo "cjgui native bridge no-resource call probe: native_object_created=false"
echo "cjgui native bridge no-resource call probe: success=true reason=none"
