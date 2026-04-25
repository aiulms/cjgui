#!/usr/bin/env zsh

export CANGJIE_HOME="/Users/jiangxuanyang/cangjie-toolchains/cangjie"
export CJ_GUI_SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
export SDKROOT="$CJ_GUI_SDKROOT"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"

source "$CANGJIE_HOME/envsetup.sh"

export LDFLAGS="-L/opt/homebrew/opt/libffi/lib ${LDFLAGS:-}"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include ${CPPFLAGS:-}"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
