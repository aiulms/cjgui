#!/usr/bin/env zsh
#
# Owner: native bridge isolated FFI probe environment。
# Truth: 只设置本地仓颉工具链与 macOS SDK 环境，服务 isolated no-resource C ABI FFI probe。
# Stop-line: 不修改 runtime package config，不接 production runtime FFI，不创建 native object。
# Same-shape Boundary Brake: 环境脚本只是 probe support，不是 runtime link、backend-ready 或 public API permission。

export CANGJIE_HOME="/Users/jiangxuanyang/cangjie-toolchains/cangjie"

KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  export CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  export CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]]; then
  export CJ_GUI_SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
fi

export SDKROOT="$CJ_GUI_SDKROOT"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"

source "$CANGJIE_HOME/envsetup.sh"
