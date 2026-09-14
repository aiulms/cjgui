#!/usr/bin/env zsh
set -euo pipefail

cjgui_notification_consumer_dir="$(cd "$(dirname "$0")" && pwd)"
zsh "$cjgui_notification_consumer_dir/build.sh"
exec python3 "$cjgui_notification_consumer_dir/test_notification_threshold_consumer.py"
