#!/usr/bin/env bash
# 消费方薄包装：转发到框架平台模拟器启动入口。
#
# 用法： bash scripts/start_emulator.sh
set -euo pipefail
_HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$_HERE/.." && pwd)"
exec bash "$LAB/../../runtime/cjgui/platforms/ohos/scripts/start_emulator.sh" "$@"
