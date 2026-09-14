#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDKROOT_PATH="${CJGUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "second consumer: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
export SDKROOT="$SDKROOT_PATH"
cd "$SCRIPT_DIR"
cjpm build --skip-script
