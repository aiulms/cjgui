#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 isolated visible-window environment probe 的
# result-envelope 语义。Metal device 为 nil 时，probe 不允许只因为
# layer.device == device 同为 nil 就输出 device-bound / display-backed true。
# Stop-line: 本脚本只做 source-level regression，不创建 NSApplication /
# NSWindow / CAMetalLayer，不执行 native probe，不写 renderer state，不扩
# public API / production C ABI。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROBE_SCRIPT="$SCRIPT_DIR/verify_native_bridge_drawable_visible_window_environment.sh"

if [[ ! -f "$PROBE_SCRIPT" ]]; then
  echo "cjgui drawable visible-window result envelope semantics: missing probe script $PROBE_SCRIPT" >&2
  exit 3
fi

required_patterns=(
  'int isolated_metal_device_available = device != nil'
  'int isolated_device_bound ='
  'isolated_metal_device_available && layer.device == device'
  'isolated_metal_device_available &&'
  'printf("isolated_metal_device_available=%s\n"'
  'printf("failure_count=%d\n", failures)'
  'visible_window_environment_failure_domain'
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -F "$pattern" "$PROBE_SCRIPT" >/dev/null 2>&1; then
    echo "cjgui drawable visible-window result envelope semantics: missing pattern $pattern" >&2
    exit 4
  fi
done

if grep -F 'int isolated_device_bound = layer.device == device' "$PROBE_SCRIPT" >/dev/null 2>&1; then
  echo "cjgui drawable visible-window result envelope semantics: stale nil-equality device-bound predicate found" >&2
  exit 5
fi

echo "cjgui drawable visible-window result envelope semantics: route_classification=drawable_visible_window_result_envelope_semantics"
echo "cjgui drawable visible-window result envelope semantics: metal_device_nil_not_device_bound=true"
echo "cjgui drawable visible-window result envelope semantics: display_backed_layer_requires_device_available=true"
echo "cjgui drawable visible-window result envelope semantics: failure_count_reported=true"
echo "cjgui drawable visible-window result envelope semantics: result_envelope_semantics_passed=true"
