#!/usr/bin/env zsh

export CANGJIE_HOME="${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}"
if [[ -z "${CJ_GUI_SDKROOT:-}" ]]; then
  export CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "$CJ_GUI_SDKROOT" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  export CJ_GUI_SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
fi
export SDKROOT="$CJ_GUI_SDKROOT"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-}"

source "$CANGJIE_HOME/envsetup.sh"

export LDFLAGS="-L/opt/homebrew/opt/libffi/lib ${LDFLAGS:-}"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include ${CPPFLAGS:-}"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
