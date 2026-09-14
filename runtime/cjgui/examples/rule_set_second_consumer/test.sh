#!/usr/bin/env zsh
set -euo pipefail
cjgui_rule_set_consumer_dir="$(cd "$(dirname "$0")" && pwd)"
set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
zsh "$cjgui_rule_set_consumer_dir/build.sh"
python3 "$cjgui_rule_set_consumer_dir/test_shared_rule_set_second_consumer.py"
exec python3 "$cjgui_rule_set_consumer_dir/test_rule_set_save_race.py"
