#!/usr/bin/env zsh
#
# Owner: production native bridge cjpm integration boundary probe。
# Truth: 只把 cjpm package build 与 production skeleton isolated compile 串成可重复验证入口。
# Stop-line: 不修改 cjpm.toml，不接 FFI，不实现 callable C ABI，不创建 native 对象。
# Same-shape Boundary Brake: 本脚本只是 build boundary evidence，不是 bridge-ready、FFI-ready、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
REPO_DIR="$(cd "$PACKAGE_DIR/../.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
SKELETON_PROBE="$SCRIPT_DIR/verify_native_bridge_skeleton_compile.sh"
TARGET_DIR="${CJGUI_NATIVE_BRIDGE_CJPM_BOUNDARY_TARGET_DIR:-/tmp/cjgui-native-bridge-cjpm-boundary-target}"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked)$'

if [[ ! -f "$CJPM_TOML" ]]; then
  echo "cjgui native bridge cjpm boundary: missing $CJPM_TOML" >&2
  exit 2
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge cjpm boundary: missing production native skeleton" >&2
  exit 3
fi

if [[ ! -x "$SKELETON_PROBE" ]]; then
  echo "cjgui native bridge cjpm boundary: missing executable skeleton probe $SKELETON_PROBE" >&2
  exit 4
fi

if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge cjpm boundary: cjpm.toml must not declare ffi.c for this slice" >&2
  exit 5
fi

if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge cjpm boundary: cjpm.toml must not wire production native skeleton yet" >&2
  exit 6
fi

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal)\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge cjpm boundary: production skeleton must not import Metal framework" >&2
  exit 7
fi

if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]+(alloc|new)\]|(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]*\*|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge cjpm boundary: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 8
fi

while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge cjpm boundary: callable symbol is outside no-resource allowlist: $callable_name" >&2
    exit 9
  fi
done < <(grep -Eoh 'cjgui_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')

if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui native bridge cjpm boundary: cjpm not found; source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh first" >&2
  exit 10
fi

echo "cjgui native bridge cjpm boundary: repo=$REPO_DIR"
echo "cjgui native bridge cjpm boundary: package=$PACKAGE_DIR"
echo "cjgui native bridge cjpm boundary: target=$TARGET_DIR"
echo "cjgui native bridge cjpm boundary: running cjpm build without scripts"

(
  cd "$PACKAGE_DIR"
  cjpm build --target-dir "$TARGET_DIR" --skip-script
)

echo "cjgui native bridge cjpm boundary: running isolated production skeleton compile"
"$SKELETON_PROBE"

echo "cjgui native bridge cjpm boundary: passed"
echo "cjgui native bridge cjpm boundary: no cjpm native source inclusion, no runtime package config mutation, no public API or pointer-return C ABI"
