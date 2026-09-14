#!/usr/bin/env zsh
set -euo pipefail

cjgui_rule_set_consumer_dir="$(cd "$(dirname "$0")" && pwd)"
sdkroot_path="${CJGUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
if [[ ! -d "$sdkroot_path" ]]; then
  echo "rule-set second consumer: unavailable SDKROOT=$sdkroot_path" >&2; exit 2
fi
set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
export SDKROOT="$sdkroot_path"
cd "$cjgui_rule_set_consumer_dir"
cjpm build --skip-script
